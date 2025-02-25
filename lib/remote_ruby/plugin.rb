# frozen_string_literal: true

module RemoteRuby
  # Base class for Plugins to execution context to insert additonal
  # code to the generated remote code.
  class Plugin
    class << self
      attr_reader :plugins

      def register_plugin(name, klass)
        @plugins ||= {}
        @plugins[name] = klass
      end

      def build_plugins(args = {})
        res = []

        Plugin.plugins.each do |name, klass|
          options = args.delete(name)

          res << klass.new(**options) if options
        end

        res
      end
    end

    def initialize(**args); end

    def code_header; end
  end
end

require 'remote_ruby/rails_plugin'
