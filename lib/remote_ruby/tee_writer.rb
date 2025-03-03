# frozen_string_literal: true

module RemoteRuby
  # Implements a tee writer that writes to multiple writers
  class TeeWriter
    attr_reader :writers

    def initialize(*writers)
      @writers = writers
    end

    def write(*args)
      writers.map { |writer| writer.write(*args) }.min
    end
  end
end
