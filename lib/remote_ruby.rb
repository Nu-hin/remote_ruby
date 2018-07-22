require 'remote_ruby/version'
require 'remote_ruby/execution_context'

# Namespace module for other RemoteRuby classes. Also contains methods, which
# are included in the global scope
module RemoteRuby
  def remotely(args = {}, &block)
    locals = args.delete(:locals)
    execution_context = ::RemoteRuby::ExecutionContext.new(**args)
    execution_context.execute(locals, &block)
  end
end

include RemoteRuby
