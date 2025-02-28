# frozen_string_literal: true

require 'base64'

module RemoteRuby
  # This class is inlined to the remote script and used
  # to collect errors and other information about the remote run.
  # It is serialized and sent back to the client.
  class RemoteContext
    attr_reader :file_name, :has_error, :error_class, :error_message, :error_backtrace, :locals, :result

    def initialize(filename)
      @file_name = filename
      @has_error = false
      @locals = {}
    end

    def error?
      @has_error
    end

    def handle_error(err)
      @error_class = err.class.to_s
      @error_message = err.message
      @error_backtrace = err.backtrace
      @has_error = true
    end

    def execute(&block)
      @result = begin
        block.call
      rescue StandardError => e
        handle_error(e)
      ensure
        locals.each_key do |name|
          locals[name] = block.binding.local_variable_get(name)
        end
      end
    end

    def dump
      Marshal.dump(self)
    end

    def unmarshal(name, data)
      locals[name] = Marshal.load(Base64.strict_decode64(data)) # rubocop:disable Security/MarshalLoad
    rescue ArgumentError
      warn("Warning: could not resolve type for '#{name}' variable")
      nil
    end
  end
end
