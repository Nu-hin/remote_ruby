# frozen_string_literal: true

require 'remote_ruby/execution_context'

module RemoteRuby
  # Module to include in the global scope to provide the `remotely` method
  module Extensions
    def remotely(args = {}, &block)
      unless defined?(REMOTE_RUBY_RSPEC_RUNNING)
        warn '[DEPRECATION] `remotely` method is deprecated and will be ' \
             'removed in v2.0. Please use `RemoteRuby::ExecutionContext#execute` directly.'
      end
      locals = args.delete(:locals)
      execution_context = ::RemoteRuby::ExecutionContext.new(**args)
      execution_context.execute(locals, &block)
    end
  end
end
