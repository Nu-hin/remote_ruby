# frozen_string_literal: true

require 'remote_ruby/version'
require 'remote_ruby/plugin'
require 'remote_ruby/execution_context'

# Namespace module for other RemoteRuby classes. Also contains methods, which
# are included in the global scope
module RemoteRuby
  def remotely(args = {}, &block)
    locals = args.delete(:locals)
    execution_context = ::RemoteRuby::ExecutionContext.new(**args)
    execution_context.execute(locals, &block)
  end

  def self.root(*params)
    root_dir = ::Gem::Specification.find_by_name('remote_ruby').gem_dir
    File.join(root_dir, *params)
  end

  def self.lib_path(*params)
    File.join(root, 'lib', *params)
  end

  def register_plugin(keyword, plugin_class)
    Plugin.register_plugin(keyword,
                           plugin_class)
  end

  def configure
    yield self
  end
end

# rubocop:disable Style/MixinUsage
include RemoteRuby
# rubocop:enable Style/MixinUsage

RemoteRuby.register_plugin(:rails, RemoteRuby::RailsPlugin)
