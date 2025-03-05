# frozen_string_literal: true

module RemoteRuby
  # Wraps the connection adapter in a text mode adapter if text mode is enabled.
  class TextModeBuilder
    attr_reader :out_tty, :err_tty, :text_mode

    def initialize(params:, out_tty: true, err_tty: true)
      @out_tty = out_tty
      @err_tty = err_tty
      @text_mode = params.delete(:text_mode) || false
    end

    def build(adapter)
      return adapter unless text_mode

      cache_mode = adapter.is_a? CacheAdapter

      tm_params = text_mode_params(adapter, cache_mode, out_tty, err_tty)

      return adapter unless tm_params[:stdout_prefix] || tm_params[:stderr_prefix]

      ::RemoteRuby::TextModeAdapter.new(adapter, **tm_params)
    end

    private

    def text_mode_params(adapter, cache_mode, out_tty, err_tty)
      tm_params = ::RemoteRuby::TextModeAdapter::DEFAULT_SETTINGS.merge(
        stdout_prefix: adapter.connection_name,
        stderr_prefix: adapter.connection_name
      )

      tm_params = tm_params.merge(text_mode) if text_mode.is_a? Hash

      disable_unless_tty = tm_params.delete(:disable_unless_tty) { |_| true }

      tm_params[:stdout_prefix] = nil if disable_unless_tty && !out_tty
      tm_params[:stderr_prefix] = nil if disable_unless_tty && !err_tty
      tm_params[:cache_prefix] = nil unless cache_mode
      tm_params
    end
  end
end
