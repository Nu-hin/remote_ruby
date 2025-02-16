# frozen_string_literal: true

module RemoteRuby
  # Decorates the source stream prepending a prefix to each line
  # read from the source
  class StreamPrefixer
    attr_reader :stream, :prefix

    def initialize(stream, prefix)
      @stream = stream
      @prefix = prefix
      @eof = false
      @prefix_needed = true
      @out_buffer = String.new
    end

    def read(max_len = nil, out_str = nil)
      res = String.new

      loop do
        res << readpartial_direct(max_len.nil? ? nil : max_len - res.length)
        break if !max_len.nil? && res.length >= max_len
      rescue EOFError
        break
      end

      out_str ||= String.new
      out_str.replace(res)
    end

    def readpartial(max_len = nil, out_str = nil)
      out_str ||= String.new
      out_str.replace(readpartial_direct(max_len))
    end

    private

    def readpartial_direct(max_len)
      if @out_buffer.empty?
        begin
          read = stream.readpartial(max_len)
          raise EOFError if read.empty?
        rescue EOFError
          @eof = true
          raise
        end

        read.each_line do |line|
          @out_buffer << prefix if @prefix_needed
          @prefix_needed = line.end_with?("\n")
          @out_buffer << line
        end
      end

      @out_buffer.slice!(0, max_len || @out_buffer.length)
    end
  end
end
