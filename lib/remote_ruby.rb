# frozen_string_literal: true

require 'remote_ruby/version'
require 'remote_ruby/rails_plugin'
require 'remote_ruby/extensions'

# Namespace module for other RemoteRuby classes. Also contains methods, which
# are included in the global scope
module RemoteRuby
  DEFAULT_CONFIG_DIR_NAME = '.remote_ruby'
  DEFAULT_CACHE_DIR_NAME = 'cache'
  DEFAULT_CODE_DIR_NAME = 'code'

  class << self
    attr_reader :plugins
    attr_accessor :cache_dir, :code_dir

    def root(*params)
      root_dir = ::Gem::Specification.find_by_name('remote_ruby').gem_dir
      File.join(root_dir, *params)
    end

    def ensure_cache_dir
      FileUtils.mkdir_p(cache_dir)
    end

    def ensure_code_dir
      FileUtils.mkdir_p(code_dir)
    end

    def lib_path(*params)
      File.join(root, 'lib', *params)
    end

    def clear_cache
      FileUtils.rm_rf(cache_dir)
    end

    def clear_code
      FileUtils.rm_rf(code_dir)
    end

    def register_plugin(name, klass)
      @plugins ||= {}
      @plugins[name] = klass
    end

    def configure
      yield self
    end
  end
end

RemoteRuby.configure do |config|
  config_dir = File.join(Dir.pwd, RemoteRuby::DEFAULT_CONFIG_DIR_NAME)
  config.cache_dir = File.join(config_dir, RemoteRuby::DEFAULT_CACHE_DIR_NAME)
  config.code_dir = File.join(config_dir, RemoteRuby::DEFAULT_CODE_DIR_NAME)

  config.register_plugin(:rails, RemoteRuby::RailsPlugin)
end
