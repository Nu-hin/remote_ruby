module RemoteRuby
  # An adapter which takes stdout and stderr from files and ignores
  # all stdin. Only used to read from cache.
  class CacheAdapter < ConnectionAdapter
    register_adapter(:cache_adapter)

    def initialize(connection_name:, cache_path:)
      @cache_path = cache_path
      @connection_name = connection_name
    end

    def connection_name
      "[CACHE] #{@connection_name}"
    end

    def open
      stdin = File.open(File::NULL, 'w')
      stdout = File.open(stdout_file_path, 'r')
      stderr = File.open(stderr_file_path, 'r')

      yield stdin, stdout, stderr
    ensure
      stderr.close
      stdout.close
      stdin.close
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
  end
end
