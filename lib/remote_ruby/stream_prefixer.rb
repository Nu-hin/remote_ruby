# frozen_string_literal: true

module RemoteRuby
  # Decorates the source stream prepending a prefix to each line
  # read from the source
  class StreamPrefixer
    attr_reader :stream, :prefix

    def initialize(stream, prefix)
      @stream = stream
      @prefix = prefix
      @prefix_needed = true
    end

    def write(data)
      res = 0
      data.each_line do |line|
        res += stream.write(prefix) if @prefix_needed
        @prefix_needed = line.end_with?("\n")
        res += stream.write(line)
      end
      res
    end
  end
end
