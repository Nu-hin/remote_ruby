# frozen_string_literal: true

require 'remote_ruby/stream_prefixer'
require 'colorize'

module RemoteRuby
  # Decorates a connection adapter.
  # Reads the output streams line-by-line and prefixes them according to the settings.
  class TextModeAdapter < ConnectionAdapter
    DEFAULT_SETTINGS = {
      stdout_mode: { color: :green, mode: :italic },
      stderr_mode: { color: :red, mode: :italic },
      cache_mode: { color: :blue, mode: :bold },
      cache_prefix: '[C] '
    }.freeze

    attr_reader :adapter, :stdout_prefix, :stderr_prefix, :cache_prefix, :stdout_mode, :stderr_mode,
                :cache_mode

    # rubocop:disable Metrics/ParameterLists
    def initialize(
      adapter,
      stdout_prefix:,
      stderr_prefix:,
      cache_prefix:,
      stdout_mode:,
      stderr_mode:,
      cache_mode:
    )
      super()
      @adapter = adapter
      @stdout_prefix = stdout_prefix
      @stderr_prefix = stderr_prefix
      @cache_prefix = cache_prefix
      @stdout_mode = stdout_mode
      @stderr_mode = stderr_mode
      @cache_mode = cache_mode
    end
    # rubocop:enable Metrics/ParameterLists

    def open(code, stdin, stdout, stderr)
      stdout_pref = "#{cache_prefix_string}#{stdout_prefix_string}"
      stderr_pref = "#{cache_prefix_string}#{stderr_prefix_string}"
      stdout = StreamPrefixer.new(stdout, stdout_pref) unless stdout_prefix_string.nil?
      stderr = StreamPrefixer.new(stderr, stderr_pref) unless stderr_prefix_string.nil?

      adapter.open(code, stdin, stdout, stderr)
    end

    private

    def stdout_prefix_string
      return nil if stdout_prefix.nil? || stdout_prefix.empty?
      return stdout_prefix if stdout_mode.nil?

      stdout_prefix.colorize(stdout_mode)
    end

    def stderr_prefix_string
      return nil if stderr_prefix.nil? || stderr_prefix.empty?
      return stderr_prefix if stderr_mode.nil?

      stderr_prefix.colorize(stderr_mode)
    end

    def cache_prefix_string
      return nil if cache_prefix.nil? || cache_prefix.empty?
      return cache_prefix if cache_mode.nil?

      cache_prefix.colorize(cache_mode)
    end
  end
end
