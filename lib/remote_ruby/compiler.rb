# frozen_string_literal: true

require 'base64'
require 'digest'
require 'erb'

module RemoteRuby
  # Receives client Ruby code, locals and their values and creates Ruby code
  # to be executed on the remote host.
  class Compiler
    def initialize(ruby_code, client_locals: {}, plugins: [])
      @ruby_code = ruby_code
      @client_locals = client_locals
      @plugins = plugins
    end

    def code_hash
      @code_hash ||= Digest::SHA256.hexdigest(compiled_code)
    end

    def compiled_code
      return @compiled_code if @compiled_code

      template_file =
        ::RemoteRuby.lib_path('remote_ruby/code_templates/compiler/main.rb.erb')
      template = ERB.new(File.read(template_file), trim_mode: '<>')
      @compiled_code = template.result(binding)
    end

    def inline_file(fname)
      File.read(::RemoteRuby.lib_path('remote_ruby', fname))
    end

    def client_locals_base64
      return @client_locals_base64 if @client_locals_base64

      @client_locals_base64 = {}

      client_locals.each do |name, data|
        base64_data = process_local(name, data)
        next if base64_data.nil?

        @client_locals_base64[name] = base64_data
      end

      @client_locals_base64
    end

    private

    attr_reader :ruby_code, :client_locals, :plugins

    def process_local(name, data)
      bin_data = Marshal.dump(data)
      Base64.strict_encode64(bin_data)
    rescue TypeError => e
      warn "Cannot send variable '#{name}': #{e.message}"
    end
  end
end
