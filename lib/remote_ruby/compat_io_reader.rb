# frozen_string_literal: true

module RemoteRuby
  # Wraps any object that responds to #readpartial with a readable IO object
  class CompatIOReader
    attr_reader :readable

    def initialize(io)
      if io.is_a?(IO)
        @readable = io
        return
      end

      raise 'Object must respond to #readpartial' unless io.respond_to?(:readpartial)

      @readable, @writeable = IO.pipe
      @thread = start(io)
    end

    def join
      return unless @writeable

      @writeable.close
      @thread.join
      @readable.close
    end

    private

    def start(io)
      Thread.new do
        IO.copy_stream(io, @writeable)
      end
    end
  end
end
