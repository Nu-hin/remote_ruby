# frozen_string_literal: true

require 'digest'
require 'openssl'
require 'erb'

module RemoteRuby
  # Encrypts the provided plaintext ruby code, and embeds it into a
  # Ruby script, that decrypts and executes it.
  class Encrypter
    attr_reader :plaintext_code

    def initialize(plaintext_code)
      @plaintext_code = plaintext_code
      encrypted_script_base64
    end

    def compiled_code
      return @compiled_code if @compiled_code

      template_file =
        ::RemoteRuby.lib_path('remote_ruby/code_templates/compiler/encrypted.rb.erb')
      template = ERB.new(File.read(template_file), trim_mode: '<>')
      @compiled_code = template.result(binding)
    end

    def key_base64
      Base64.strict_encode64(@key)
    end

    private

    def encrypted_script_base64
      return @encrypted_script_base64 if @encrypted_script_base64

      cipher = OpenSSL::Cipher.new('AES-256-CBC')
      cipher.encrypt
      @key = cipher.random_key
      iv = cipher.random_iv

      cipher_text = cipher.update(plaintext_code) + cipher.final
      @encrypted_script_base64 ||= Base64.strict_encode64(iv + cipher_text)
    end
  end
end
