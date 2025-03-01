# frozen_string_literal: true

module RemoteRuby
  # Builds connection adapter based on the provided parameters.
  # Can wrap the adapter in caching and text mode adapters.
  class AdapterBuilder
    attr_reader :adapter_params, :use_cache, :save_cache, :text_mode

    def initialize(adapter_klass: nil, use_cache: false, save_cache: false, text_mode: false, **params)
      @adapter_klass = adapter_klass
      @use_cache = use_cache
      @save_cache = save_cache
      @text_mode = text_mode
      @adapter_params = params

      RemoteRuby.ensure_cache_dir if save_cache
    end

    def adapter_klass
      return @adapter_klass if @adapter_klass

      if adapter_params[:host]
        ::RemoteRuby::SSHAdapter
      else
        ::RemoteRuby::TmpFileAdapter
      end
    end

    def build(code_hash, out_tty: true, err_tty: true)
      res = adapter_klass.new(**adapter_params)

      cache_mode = use_cache && cache_exists?(code_hash)

      res = if cache_mode
              cache_adapter(code_hash, res.connection_name)
            elsif save_cache
              caching_adapter(res, code_hash)
            else
              res
            end

      wrap_text_mode(res, cache_mode, out_tty, err_tty)
    end

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

    def wrap_text_mode(adapter, cache_mode, out_tty, err_tty)
      return adapter unless text_mode

      tm_params = text_mode_params(adapter, cache_mode, out_tty, err_tty)

      return adapter unless tm_params[:stdout_prefix] || tm_params[:stderr_prefix]

      ::RemoteRuby::TextModeAdapter.new(adapter, **tm_params)
    end

    def cache_adapter(code_hash, connection_name)
      ::RemoteRuby::CacheAdapter.new(
        cache_path: cache_path(code_hash),
        connection_name: connection_name
      )
    end

    def caching_adapter(adapter, code_hash)
      ::RemoteRuby::CachingAdapter.new(
        adapter: adapter,
        cache_path: cache_path(code_hash)
      )
    end

    def context_hash(code_hash)
      Digest::MD5.hexdigest(
        self.class.name +
        adapter_klass.name.to_s +
        adapter_params.to_s +
        code_hash
      )
    end

    def cache_path(code_hash)
      hsh = context_hash(code_hash)
      File.join(RemoteRuby.cache_dir, hsh)
    end

    def cache_exists?(code_hash)
      hsh = cache_path(code_hash)
      File.exist?("#{hsh}.stdout") || File.exist?("#{hsh}.stderr") || File.exist?("#{hsh}.result")
    end
  end
end
