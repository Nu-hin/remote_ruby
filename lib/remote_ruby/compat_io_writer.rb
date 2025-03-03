# frozen_string_literal: true

module RemoteRuby
  # Wraps any object that responds to #write with a writeable IO object
  class CompatIOWriter
    attr_reader :writeable

    def initialize(io)
      raise 'Object must respond to #write' unless io.respond_to?(:write)

      @readable, @writeable = IO.pipe
      @thread = start(io)
    end

    private

    def start(io)
      Thread.new do
        loop do
          data = @readable.readpartial(4096)
          io.write(data)
        end
      rescue EOFError
        @readable.close
      end
    end
  end
end
