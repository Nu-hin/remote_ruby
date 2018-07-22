module RemoteRuby
  # An adapter which takes stdout and stderr from files and ignores
  # all stdin. Only used to read from cache.
  class CacheAdapter < ConnectionAdapter
    def initialize(connection_name:, cache_path:)
      @cache_path = cache_path
      @connection_name = connection_name
    end

    def connection_name
      "[CACHE] #{@connection_name}"
    end

    def open(_code)
      stdout = File.open(stdout_file_path, 'r')
      stderr = File.open(stderr_file_path, 'r')

      yield stdout, stderr
    ensure
      stderr.close unless stderr.closed?
      stdout.close unless stdout.closed?
      stdin.close  unless stdin.closed?
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
