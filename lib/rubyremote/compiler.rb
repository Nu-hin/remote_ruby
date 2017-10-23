require 'base64'

module Rubyremote
	class Compiler
		def initialize
		end

		def compile(ruby_code, id, client_locals = {})
      code = StringIO.new
      code.puts("require('base64')")

      code.puts "CLIENT_LOCALS_NAMES = %i(#{client_locals.keys.join(' ')})"
      code.puts "MARSHALLED_LOCALS_NAMES = CLIENT_LOCALS_NAMES + [:__return_val__#{id}]"

      client_locals.each do |name, data|
        bin_data = Marshal.dump(data)
        base64_data = Base64.encode64(bin_data)
        code.puts <<-RUBY
          #{name} = begin
            Marshal.load(Base64.decode64('#{base64_data}'))
          rescue ArgumentError
            STDERR.puts("Warning: could not resolve type for #{name} variable")
            nil
          end
        RUBY
      end

      code.puts <<-RUBY
        __context_id__ = #{id}

        __return_val__#{id} = begin
          # Start of client code
          #{ruby_code}
          # End of client code
        end
      RUBY

      code.puts <<-'RUBY'
        # Marshalling local variables and result

        puts "%%%MARSHAL_#{__context_id__}"

        MARSHALLED_LOCALS_NAMES.each do |lv|
          data = Marshal.dump(eval(lv.to_s))
          data_length = data.size
          puts "#{lv}:#{data_length}"
          STDOUT.write(data)
        end
      RUBY

      code.string
    end

	end
end
