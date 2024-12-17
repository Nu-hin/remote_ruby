# frozen_string_literal: true

module RemoteRuby
  # An adapter which takes stdout and stderr from files and ignores
  # all stdin. Only used to read from cache.
  class CacheAdapter < ConnectionAdapter
    def initialize(cache_path:)
      super
      @cache_path = cache_path
    end

    def open(_code)
      stdout = File.open(stdout_file_path, 'r')
      stderr = File.open(stderr_file_path, 'r')

      yield nil, stdout, stderr
    ensure
      stderr.close unless stderr.closed?
      stdout.close unless stdout.closed?
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
