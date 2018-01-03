require 'base64'
require 'digest'

module Rubyremote
  class Compiler
    def initialize(ruby_code, client_locals = {})
      @ruby_code = ruby_code
      @client_locals = client_locals
    end

    def code_hash
      @code_hash = Digest::SHA256.hexdigest(ruby_code.to_s + client_locals.to_s)
    end

    def compile
      code = StringIO.new
      code.puts("require('base64')")

      code.puts "CLIENT_LOCALS_NAMES = %i(#{client_locals.keys.join(' ')})"
      code.puts 'MARSHALLED_LOCALS_NAMES = CLIENT_LOCALS_NAMES + [:__return_val__]'

      client_locals.each do |name, data|
        bin_data = Marshal.dump(data)
        base64_data = Base64.encode64(bin_data)
        code.puts <<-RUBY
          #{name} = begin
            Marshal.load(Base64.decode64('#{base64_data}'))
          rescue ArgumentError
            warn("Warning: could not resolve type for #{name} variable")
            nil
          end
        RUBY
      end

      code.puts <<-RUBY
        __return_val__ = begin
          # Start of client code
          #{ruby_code}
          # End of client code
        end
      RUBY

      code.puts <<-'RUBY'
        # Marshalling local variables and result

        puts "%%%MARSHAL"

        MARSHALLED_LOCALS_NAMES.each do |lv|
          data = Marshal.dump(eval(lv.to_s))
          data_length = data.size
          puts "#{lv}:#{data_length}"
          $stdout.write(data)
        end
      RUBY

      code.string
    end

    private

    attr_reader :ruby_code, :client_locals
  end
end
