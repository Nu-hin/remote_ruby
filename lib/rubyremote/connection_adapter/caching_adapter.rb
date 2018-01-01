require 'rubyremote/stream_cacher'

module Rubyremote
  class CachingAdapter < ConnectionAdapter
    def initialize(cache_path: cache_path, adapter: adapter)
      @cache_path = cache_path
      @adapter = adapter
    end

    def connection_name
      adapter.connection_name
    end

    def open
      result = nil

      stderr_cache = File.open(stderr_file_path, 'w')
      stdout_cache = File.open(stdout_file_path, 'w')

      adapter.open do |stdin, stdout, stderr|
        yield stdin,
          ::Rubyremote::StreamCacher.new(stdout, stdout_cache),
          ::Rubyremote::StreamCacher.new(stderr, stderr_cache)
      end
    ensure
      stdout_cache.close
      stderr_cache.close
    end

    private

    attr_reader :cache_path, :adapter

    def stdout_file_path
      "#{cache_path}.stdout"
    end

    def stderr_file_path
      "#{cache_path}.stderr"
    end
  end
end
