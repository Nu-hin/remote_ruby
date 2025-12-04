# frozen_string_literal: true

module RemoteRuby
  # Builds connection adapter based on the provided parameters.
  # Can wrap the adapter in caching and text mode adapters.
  class AdapterBuilder
    attr_reader :adapter_params, :use_cache, :save_cache, :cache_ttl, :text_mode

    def initialize(adapter_klass: nil, use_cache: false, save_cache: false, cache_ttl: 0, **params)
      @adapter_klass = adapter_klass
      @use_cache = use_cache
      @save_cache = save_cache
      @cache_ttl = cache_ttl
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

    def build(code_hash, encryption_key_base64: nil)
      res = adapter_klass.new(**adapter_params, encryption_key_base64: encryption_key_base64)

      cache_mode = use_cache && cache_exists?(code_hash)

      if cache_mode
        cache_adapter(code_hash, res.connection_name)
      elsif save_cache
        caching_adapter(res, code_hash)
      else
        res
      end
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

    def expire_cache(fnames)
      return if cache_ttl <= 0

      expired = fnames.any? do |fname|
        File.exist?(fname) && Time.now - File.mtime(fname) > cache_ttl
      end

      fnames.each { |f| FileUtils.rm_f(f) } if expired
      nil
    end

    def cache_exists?(code_hash)
      path = cache_path(code_hash)
      fnames = ["#{path}.stdout", "#{path}.stderr", "#{path}.result"]
      expire_cache(fnames)
      fnames.any? { |f| File.exist?(f) }
    end
  end
end
