# frozen_string_literal: true

module RemoteRuby
  # Wraps any object that responds to #readpartial with a readable IO object
  class CompatIOReader
    attr_reader :readable

    def initialize(io)
      raise 'Object must respond to #readpartial' unless io.respond_to?(:readpartial)

      @readable, @writeable = IO.pipe
      @thread = start(io)
    end

    private

    def start(io)
      Thread.new do
        loop do
          data = io.readpartial(4096)
          @writeable.write(data)
        end
      rescue EOFError
        @writeable.close
      end
    end
  end
end
