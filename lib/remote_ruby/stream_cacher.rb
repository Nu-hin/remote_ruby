module RemoteRuby
  # Decorates the source stream and writes to the cache stream as
  # the source is being read
  class StreamCacher
    def initialize(source_stream, cache_stream)
      @source_stream = source_stream
      @cache_stream = cache_stream
    end

    def read(*args)
      res = source_stream.read(*args)
      cache_stream.write(res)
      res
    end

    def readline
      res = source_stream.readline
      cache_stream.write(res)
      res
    end

    def eof?
      source_stream.eof?
    end

    def close
      source_stream.close
    end

    private

    attr_reader :source_stream, :cache_stream
  end
end
