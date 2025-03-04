# frozen_string_literal: true

module RemoteRuby
  # Wraps any object that responds to #write with a writeable IO object
  class CompatIOWriter
    attr_reader :writeable

    def initialize(io)
      if io.is_a?(IO)
        @writeable = io
        return
      end

      raise 'Object must respond to #write' unless io.respond_to?(:write)

      @readable, @writeable = IO.pipe
      @thread = start(io)
    end

    private

    def start(io)
      Thread.new do
        IO.copy_stream(@readable, io)
      end
    end
  end
end
