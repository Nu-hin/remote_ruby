# frozen_string_literal: true

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

      block.binding.local_variables.each do |name|
        value = block.binding.eval(name.to_s)
        next if ignored_type?(value)

        locals[name] = value
      end

      locals
    end

    private

    def ignored_type?(var)
      ignore_types.any? { |klass| var.is_a? klass }
    end
  end
end
