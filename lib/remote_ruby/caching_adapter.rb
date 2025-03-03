# frozen_string_literal: true

require 'remote_ruby/tee_writer'

module RemoteRuby
  # An adapter decorator which extends the adapter passed in to its
  # initializer to cache stdout and stderr to local filesystem
  class CachingAdapter < ConnectionAdapter
    def initialize(cache_path:, adapter:)
      super
      @cache_path = cache_path
      @adapter = adapter
    end

    def open(code, stdin, stdout, stderr)
      res = nil
      with_cache do |stdout_cache, stderr_cache, result_cache|
        tee_out = ::RemoteRuby::TeeWriter.new(stdout, stdout_cache)
        tee_err = ::RemoteRuby::TeeWriter.new(stderr, stderr_cache)

        res = adapter.open(code, stdin, tee_out, tee_err)
        result_cache.write(res)
      end

      res
    end

    def connection_name
      adapter.connection_name
    end

    private

    attr_reader :cache_path, :adapter

    def with_cache
      stderr_cache = File.open(stderr_file_path, 'wb')
      stdout_cache = File.open(stdout_file_path, 'wb')
      result_cache = File.open(result_file_path, 'wb')

      yield stdout_cache, stderr_cache, result_cache
    ensure
      stdout_cache.close
      stderr_cache.close
      result_cache.close
    end

    def stdout_file_path
      "#{cache_path}.stdout"
    end

    def stderr_file_path
      "#{cache_path}.stderr"
    end

    def result_file_path
      "#{cache_path}.result"
    end
  end
end
