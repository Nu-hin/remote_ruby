require 'remote_ruby/stream_prefixer'
require 'colorize'

module RemoteRuby
  class TextModeAdapter < ConnectionAdapter
    attr_reader :adapter, :stdout_prefix, :stderr_prefix, :cache_prefix, :cache_used, :stdout_mode, :stderr_mode,
                :cache_mode

    def initialize(
      adapter:,
      stdout_prefix:,
      stderr_prefix:,
      cache_prefix:,
      cache_used:,
      stdout_mode:,
      stderr_mode:,
      cache_mode:
    )
      super
      @adapter = adapter
      @stdout_prefix = stdout_prefix
      @stderr_prefix = stderr_prefix
      @cache_prefix = cache_prefix
      @cache_used = cache_used
      @stdout_mode = stdout_mode
      @stderr_mode = stderr_mode
      @cache_mode = cache_mode
    end

    def open(code)
      adapter.open(code) do |stdin, stdout, stderr|
        stdout_pref = "#{cache_prefix_string}#{stdout_prefix_string}"
        stderr_pref = "#{cache_prefix_string}#{stderr_prefix_string}"
        stdout = StreamPrefixer.new(stdout, stdout_pref)
        stderr = StreamPrefixer.new(stderr, stderr_pref)

        yield stdin, stdout, stderr
      end
    end

    def with_result_stream(&block)
      adapter.with_result_stream(&block)
    end

    private

    def stdout_prefix_string
      return nil if stdout_prefix.nil? || stdout_prefix.empty?
      return stdout_prefix if stdout_mode.nil?

      stdout_prefix.colorize(**stdout_mode)
    end

    def stderr_prefix_string
      return nil if stderr_prefix.nil? || stderr_prefix.empty?
      return stderr_prefix if stderr_mode.nil?

      stderr_prefix.colorize(**stderr_mode)
    end

    def cache_prefix_string
      return nil unless cache_used
      return nil if cache_prefix.nil? || cache_prefix.empty?
      return cache_prefix if cache_mode.nil?

      cache_prefix.colorize(**cache_mode)
    end
  end
end
