require 'base64'
require 'digest'
require 'erb'

module RemoteRuby
  class Compiler
    def initialize(ruby_code, client_locals: {}, ignore_types: [], flavours: [])
      @ruby_code = ruby_code
      @client_locals = client_locals
      @ignore_types = Array(ignore_types)
      @flavours = flavours
    end

    def code_hash
      @code_hash = Digest::SHA256.hexdigest(ruby_code.to_s + client_locals.to_s)
    end

    def compile
      client_locals_base64 = {}

      client_locals.each do |name, data|
        begin
          next unless check_type(data)
          bin_data = Marshal.dump(data)
          base64_data = Base64.strict_encode64(bin_data)
          client_locals_base64[name] = base64_data
        rescue TypeError => e
          warn "Cannot send variable #{name}: #{e.message}"
        end
      end

      template_file = File.expand_path('../code_templates/compiler/main.rb.erb', __FILE__)
      template = ERB.new(File.read(template_file))
      template.result(binding)
    end

    private

    def check_type(var)
      ignore_types.each do |klass|
        return false if var.is_a? klass
      end

      true
    end

    def code_headers
      flavours.map(&:code_header)
    end

    attr_reader :ruby_code, :client_locals, :ignore_types, :flavours
  end
end
