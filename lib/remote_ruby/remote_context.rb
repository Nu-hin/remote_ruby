# frozen_string_literal: true

module RemoteRuby
  # This class is inlined to the remote script and used
  # to collect errors and other information about the remote run.
  # It is serialized and sent back to the client.
  class RemoteContext
    attr_accessor :file_name, :has_error, :error_class, :error_message, :error_backtrace

    def initialize
      @file_name = __FILE__
      @has_error = false
    end

    def handle_error(err)
      @error_class = err.class.to_s
      @error_message = err.message
      @error_backtrace = err.backtrace
      @has_error = true
    end
  end
end
