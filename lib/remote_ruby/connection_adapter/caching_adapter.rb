# frozen_string_literal: true

require 'remote_ruby/stream_cacher'

module RemoteRuby
  # An adapter decorator which extends the adapter passed in to its
  # initializer to cache stdout and stderr to local filesystem
  class CachingAdapter < ConnectionAdapter
    def initialize(cache_path:, adapter:)
      super
      @cache_path = cache_path
      @adapter = adapter
    end

    def open(code)
      with_cache do |stdout_cache, stderr_cache|
        adapter.open(code) do |stdin, stdout, stderr|
          yield stdin, ::RemoteRuby::StreamCacher.new(stdout, stdout_cache),
          ::RemoteRuby::StreamCacher.new(stderr, stderr_cache)
        end
      end
    end

    def with_result_stream
      File.open(result_file_path, 'w') do |result_cache|
        adapter.with_result_stream do |stream|
          yield ::RemoteRuby::StreamCacher.new(stream, result_cache)
        end
      end
    end

    def connection_name
      adapter.connection_name
    end

    private

    attr_reader :cache_path, :adapter

    def with_cache
      stderr_cache = File.open(stderr_file_path, 'w')
      stdout_cache = File.open(stdout_file_path, 'w')

      yield stdout_cache, stderr_cache
    ensure
      stdout_cache.close
      stderr_cache.close
    end

    def result_file_path
      "#{cache_path}.result"
    end

    def stdout_file_path
      "#{cache_path}.stdout"
    end

    def stderr_file_path
      "#{cache_path}.stderr"
    end
  end
end
