require 'rubyremote/stream_cacher'

module Rubyremote
  class Cacher < ConnectionAdapter
    def initialize(cache_path, streamer)
      @cache_path = cache_path
      @streamer = streamer
    end

    def connection_name
      streamer.connection_name
    end

    def open
      result = nil

      stderr_cache = File.open(stderr_file_path, 'w')
      stdout_cache = File.open(stdout_file_path, 'w')

      streamer.open do |stdin, stdout, stderr|
        yield stdin,
          ::Rubyremote::StreamCacher.new(stdout, stdout_cache),
          ::Rubyremote::StreamCacher.new(stderr, stderr_cache)
      end
    ensure
      stdout_cache.close
      stderr_cache.close
    end

    private

    attr_reader :cache_path, :streamer

    def stdout_file_path
      "#{cache_path}.stdout"
    end

    def stderr_file_path
      "#{cache_path}.stderr"
    end
  end
end
