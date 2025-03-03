# frozen_string_literal: true

module RemoteRuby
  # An adapter which takes stdout, stderr and result streams
  # from files and ignores all stdin. Only used to read from cache.
  class CacheAdapter < ConnectionAdapter
    attr_reader :connection_name

    def initialize(cache_path:, connection_name:)
      super
      @cache_path = cache_path
      @connection_name = connection_name
    end

    def open(_code, _stdin, stdout, stderr)
      IO.copy_stream(stdout_file_path, stdout)
      IO.copy_stream(stderr_file_path, stderr)

      File.binread(result_file_path) if result_file_path
    end

    private

    attr_reader :cache_path

    def stdout_file_path
      fp = "#{cache_path}.stdout"
      File.exist?(fp) ? fp : File::NULL
    end

    def stderr_file_path
      fp = "#{cache_path}.stderr"
      File.exist?(fp) ? fp : File::NULL
    end

    def result_file_path
      fp = "#{cache_path}.result"
      File.exist?(fp) ? fp : File::NULL
    end
  end
end
