require 'remote_ruby/version'
require 'remote_ruby/execution_context'

module RemoteRuby
  def remotely(**args, &block)
    execution_context = ::RemoteRuby::ExecutionContext.new(args)
    execution_context.execute(&block)
  end
end

include RemoteRuby
