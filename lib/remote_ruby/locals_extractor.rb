# frozen_string_literal: true

module RemoteRuby
  # Contains methods to extract local variables from a binding object as a
  # hash, and to assign local variables from a given hash
  class LocalsExtractor
    def self.extract(binder)
      binder.local_variables.map do |name|
        [name.to_sym, binder.eval(name.to_s)]
      end
    end

    def self.assign(binder, locals)
      locals.each do |name, val|
        binder.local_variable_set(name, val)
      end
    end
  end
end
