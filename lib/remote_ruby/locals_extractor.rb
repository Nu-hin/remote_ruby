module RemoteRuby
  # Extracts local variable from given context
  class LocalsExtractor
    attr_reader :block, :ignore_types

    def initialize(block, ignore_types: [])
      @block = block
      @ignore_types = Array(ignore_types)
    end

    def locals
      locals = {}

      local_variable_names.each do |name|
        value = block.binding.eval(name.to_s)
        next if ignored_type?(value)

        locals[name] = value
      end

      locals
    end

    private

    def local_variable_names
      if RUBY_VERSION >= '2.2'
        block.binding.local_variables
      else
        # A hack to support Ruby 2.1 due to the absence
        # of Binding#local_variables method. For some reason
        # just calling `block.binding.send(:local_variables)`
        # returns variables of the current context.
        block.binding.eval('binding.send(:local_variables)')
      end
    end

    def ignored_type?(var)
      ignore_types.any? { |klass| var.is_a? klass }
    end
  end
end
