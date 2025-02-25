# frozen_string_literal: true

require 'remote_ruby/version'
require 'remote_ruby/plugin'
require 'remote_ruby/mixin'

# Namespace module for other RemoteRuby classes. Also contains methods, which
# are included in the global scope
module RemoteRuby
  def self.root(*params)
    root_dir = ::Gem::Specification.find_by_name('remote_ruby').gem_dir
    File.join(root_dir, *params)
  end

  def self.lib_path(*params)
    File.join(root, 'lib', *params)
  end

  def self.register_plugin(keyword, plugin_class)
    Plugin.register_plugin(keyword,
                           plugin_class)
  end

  def self.configure
    yield self
  end
end

# rubocop:disable Style/MixinUsage
include RemoteRuby::Mixin
# rubocop:enable Style/MixinUsage

RemoteRuby.register_plugin(:rails, RemoteRuby::RailsPlugin)
