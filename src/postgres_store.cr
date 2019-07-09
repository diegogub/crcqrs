require "pg"

module Crcqrs
  class PostgresStore < Crcqrs::Store
    @conn_string : String = ""
    @conn : DB::Database
    @app : String

    def initialize(@app, host = "127.0.0.1", port = "5432", user = "postgres", password = "")
      @user = user
      @host = host
      @port = port
      @password = password
      @conn_string = "postgres://#{@user}@#{@host}:#{@port}?max_pool_size=1000&initial_pool_size=10"
      @db = "#{@app}_es"
      @conn = DB.open(@conn_string)
    end

    def init
      begin
        conn = @conn.checkout
        begin
          puts "CREATING DATABASE #{@db}:"
          puts conn.exec("CREATE DATABASE #{@db};")
        rescue
        end
        sleep 1
      ensure
        @conn.close
      end

      begin
        # reconnect to databse
        @conn_string = "postgres://#{@user}@#{@host}:#{@port}/#{@db}?max_pool_size=1000&initial_pool_size=10"
        @conn = DB.open(@conn_string)

        conn = @conn.checkout

        puts conn.exec("
                 CREATE TABLE IF NOT EXISTS events (
                    id                  TEXT UNIQUE NOT NULL,
                    stream              TEXT NOT NULL,
                    version             INT  NOT NULL,
                    correlation_version INT  NOT NULL,
                    type                TEXT NOT NULL,
                    data                JSONB NOT NULL,
                    PRIMARY KEY(stream,version)
                 )")

        puts conn.exec("
                 CREATE TABLE IF NOT EXISTS projections (
                    id                  TEXT UNIQUE NOT NULL,
                    version             INT  NOT NULL,
                    error               TEXT,
                    PRIMARY KEY(id)
                 )")

        puts conn.exec("
                 CREATE TABLE IF NOT EXISTS snapshots (
                    stream              TEXT NOT NULL,
                    version             INT  NOT NULL,
                    data                JSONB NOT NULL,
                    PRIMARY KEY(stream)
                 )")

        puts conn.exec("CREATE INDEX ON events(version);")
        puts conn.exec("CREATE UNIQUE INDEX ON events(correlation_version);")

        # save event with lock
        puts conn.exec("
                 CREATE OR REPLACE FUNCTION save_event_lock(TEXT,TEXT,TEXT,JSONB,INTEGER) RETURNS INTEGER
                 LANGUAGE plpgsql
                 AS $$
                 DECLARE
                    current INTEGER := -1;
                    cur_correlative INTEGER := -1;
                    next_correlative INTEGER := -1;
                    next_version INTEGER := -1;
                 BEGIN
                    BEGIN
                        SELECT INTO current version FROM events WHERE stream = $2 ORDER BY version DESC LIMIT 1;
                        SELECT current + 1 INTO next_version;

                        IF current != $5 THEN
                            RETURN -2;
                        END IF;

                        SELECT INTO cur_correlative correlation_version FROM events ORDER BY correlation_version DESC LIMIT 1;
                        next_correlative := cur_correlative + 1;

                        IF next_version IS NULL THEN
                            IF $5 != -1 THEN
                                RETURN -2;
                            END IF;

                            IF next_correlative IS NULL THEN
                                INSERT INTO events(id,stream,version,correlation_version,type,data) VALUES($1,$2,0,0,$3,$4);
                            ELSE
                                INSERT INTO events(id,stream,version,correlation_version,type,data) VALUES($1,$2,0,next_correlative,$3,$4);
                            END IF;
                        ELSE
                            INSERT INTO events(id,stream,version,correlation_version,type,data) VALUES($1,$2,next_version,next_correlative,$3,$4);
                        END IF;

                        IF next_version IS NULL THEN
                            RETURN 0;
                        ELSE
                            RETURN next_version;
                        END IF;

                    EXCEPTION WHEN OTHERS THEN
                        RETURN -3;
                    END;
                 END;
                 $$
                ")

        # save event
        puts conn.exec("
                 CREATE OR REPLACE FUNCTION save_event(TEXT,TEXT,TEXT,JSONB) RETURNS INTEGER
                 LANGUAGE plpgsql
                 AS $$
                 DECLARE
                    current INTEGER := -1;
                    cur_correlative INTEGER := -1;
                    next_correlative INTEGER := -1;
                    next_version INTEGER := -1;
                 BEGIN
                    BEGIN
                        SELECT INTO current version FROM events WHERE stream = $2 ORDER BY version DESC LIMIT 1;
                        SELECT current + 1 INTO next_version;

                        SELECT INTO cur_correlative correlation_version FROM events ORDER BY correlation_version DESC LIMIT 1;
                        next_correlative := cur_correlative + 1;

                        IF next_version IS NULL THEN
                            IF next_correlative IS NULL THEN
                                INSERT INTO events(id,stream,version,correlation_version,type,data) VALUES($1,$2,0,0,$3,$4);
                            ELSE
                                INSERT INTO events(id,stream,version,correlation_version,type,data) VALUES($1,$2,0,next_correlative,$3,$4);
                            END IF;
                        ELSE
                            INSERT INTO events(id,stream,version,correlation_version,type,data) VALUES($1,$2,next_version,next_correlative,$3,$4);
                        END IF;

                        IF next_version IS NULL THEN
                            RETURN 0;
                        ELSE
                            RETURN next_version;
                        END IF;
                    EXCEPTION WHEN OTHERS THEN
                        RETURN -3;
                    END;
                 END;
                 $$
                ")
      ensure
        case conn
        when Nil
        else
          conn.close
        end
      end
    end

    def version(stream : String) : (Int64 | StoreError)
      begin
        conn = @conn.checkout
        args = [] of DB::Any
        args << stream
        res = conn.query_one("select COALESCE(version,-1) FROM events WHERE stream = $1 ORDER BY version DESC LIMIT 1;", args, &.read(Int32).to_i64)
        if res == -1
          StoreError::NotFound
        else
          return res
        end
      ensure
        conn.release
      end
    end

    def save(stream : String, event : Event, create = false, lock = -1) : (Int64 | StoreError)
      conn = @conn.checkout
      begin
        args = [] of DB::Any
        args << event.id
        args << stream
        args << event.type
        args << event.to_json
        if create
          res = conn.query_one("SELECT save_event_lock($1,$2,$3,$4,-1);", args, &.read(Int32).to_i64)
          case res
          when -1
            StoreError::Failed
          when -3
            StoreError::Exist
          else
            return res
          end
        end

        if lock > -1
          args << lock
          res = conn.query_one("SELECT save_event_lock($1,$2,$3,$4,$5);", args, &.read(Int32).to_i64)
          case res
          when -1
            StoreError::Failed
          when -3
            StoreError::Lock
          else
            return res
          end
        else
          res = conn.query_one("SELECT save_event($1,$2,$3,$4);", args, &.read(Int32).to_i64)
          case res
          when -1
            StoreError::Failed
          when -3
            StoreError::Lock
          else
            return res
          end
        end
      ensure
        conn.release
      end
    end

    def get_events(agg : Crcqrs::AggregateRoot, stream : String, from : Int64) : (StreamCursor | StoreError)
      c = StreamCursor.new
      spawn do
        begin
          conn = @conn.checkout
          args = [] of DB::Any
          args << stream
          args << from
          q = "SELECT version,type, data FROM events WHERE stream = $1 AND version >= $2 ORDER BY version ASC"
          version = -1
          type = ""
          data = JSON.parse("{}")
          conn.query q, args do |rs|
            rs.each do
              version, type, data = rs.read(Int32, String, JSON::Any)
              event = agg.gen_event(type, data.to_json)
              event.version = version.to_i64
              c.channel.send event
            end
            rs.close
          end
          conn.close

          while !c.channel.empty?
            if c.channel.empty?
              break
            end
            sleep 0.000001
          end
          c.channel.close
        ensure
          @conn.close
        end
      end
      c
    end

    def stream_exist(stream : String) : Bool
      q = "SELECT stream FROM events WHERE stream = $1 LIMIT 1"
      args = [] of DB::Any
      args << stream
      exist = false
      @conn.query q, args do |rs|
        rs.each do
          rs.read(String)
          exist = true
        end
      end

      exist
    end

    def correlative_version : Int64
      res = @conn.query_one("SELECT correlation_version FROM events ORDER BY correlation_version DESC LIMIT 1", &.read(Int32).to_i64)
      case res
      when Int64
        res
      else
        -1_i64
      end
    end

    def get_events_correlative(from : Int64) : (StreamCursor | StoreError)
      c = StreamCursor.new
      spawn do
        begin
          conn = @conn.checkout
          args = [] of DB::Any
          args << from
          q = "SELECT id,stream,version,type,data FROM events WHERE correlation_version >= $1 ORDER BY correlation_version ASC"
          version = -1
          type = ""
          data = JSON.parse("{}")
          conn.query q, args do |rs|
            rs.each do
              id, stream, version, type, data = rs.read(String, String, Int32, String, JSON::Any)
              event = RawEvent.new
              event.stream = stream
              event.id = id
              event.type = type
              event.version = version.to_i64
              event.data = data
              c.channel.send event
            end
            rs.close
          end
          conn.close

          while !c.channel.empty?
            if c.channel.empty?
              break
            end
            sleep 0.000001
          end
          c.channel.close
        ensure
          @conn.close
        end
      end
      c
    end

    def cache(stream : String, agg : Aggregate)
      begin
        conn = @conn.checkout
        args = [] of DB::Any
        args << stream
        args << agg.version
        args << agg.to_json
        conn.query("INSERT INTO snapshots (stream, version, data) VALUES ($1, $2, $3) ON CONFLICT (stream) DO UPDATE SET data = EXCLUDED.data, version = EXCLUDED.version;", args)
        @conn.close
      ensure
        case conn
        when Nil
        else
          conn.close
        end
      end
    end

    def hit_cache(stream : String) : (CacheValue | StoreError)
      args = [] of DB::Any
      args << stream
      found = false
      val = CacheValue.new
      begin
        conn = @conn.checkout
        conn.query("SELECT version,data FROM snapshots WHERE stream = $1 LIMIT 1", args) do |rs|
          rs.each do
            version, data = rs.read(Int32, JSON::Any)
            val.version = version.to_i64
            val.data = data.to_json
            found = true
          end
          rs.close
        end
        conn.close
      ensure
        case conn
        when Nil
        else
          conn.close
        end
      end

      if found
        val
      else
        StoreError::MissCache
      end
    end

    def projection(id : String, version : Int64, error : String)
      begin
        conn = @conn.checkout
        args = [] of DB::Any
        args << id
        args << version
        args << error
        conn.query("INSERT INTO projections (id, version, error) VALUES($1,$2,$3) ON CONFLICT (id) DO UPDATE SET version = EXCLUDED.version, error = EXCLUDED.error", args)
        conn.close
        @conn.close
      ensure
        case conn
        when Nil
        else
          conn.close
        end
      end
    end

    def get_event(id : String) : (Event | StoreError)
      found = false
    end

    def get_projection(id : String) : ProjectionStatus
      begin
        args = [] of DB::Any
        args << id
        conn = @conn.checkout
        status = ProjectionStatus.new
        conn.query("SELECT id,version,error FROM projections WHERE id = $1", args) do |rs|
          rs.each do
            id, v, err = rs.read(String, Int32, String)
            status.id = id
            status.version = v.to_i64
            status.error = err
          end
        end

        conn.close
        @conn.close

        status
      ensure
        case conn
        when Nil
        else
          conn.close
        end
      end
    end

    def list_projections : Array(ProjectionStatus)
      list = Array(ProjectionStatus).new
      begin
        conn = @conn.checkout
        conn.query("SELECT id,version,error FROM projections") do |rs|
          rs.each do
            id, v, err = rs.read(String, Int32, String)
            status = ProjectionStatus.new
            status.id = id
            status.version = v.to_i64
            status.error = err
          end
        end
      ensure
        case conn
        when Nil
        else
          conn.close
        end
      end
    end
  end
end
