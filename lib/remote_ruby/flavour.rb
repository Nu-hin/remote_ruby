# frozen_string_literal: true

module RemoteRuby
  # Base class for Flavours: addons to execution context to insert additonal
  # code to the generated remote code.
  class Flavour
    def self.build_flavours(args = {})
      res = []

      {
        rails: RemoteRuby::RailsFlavour
      }.each do |name, klass|
        options = args.delete(name)

        res << klass.new(**options) if options
      end

      res
    end

    def initialize(**args); end

    def code_header; end
  end
end

require 'remote_ruby/flavour/rails_flavour'
