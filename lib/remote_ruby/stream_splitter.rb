# frozen_string_literal: true

module RemoteRuby
  # Implements a reader. Receives a steram and a terminator.
  # Reads from the stream until the terminator is found.
  class StreamSplitter
    attr_reader :stream, :terminator
    attr_accessor :buffer

    def self.split(stream, terminator)
      [
        new(stream, terminator),
        stream
      ]
    end

    def initialize(stream, terminator)
      @stream = stream
      @eof = false
      @terminator = terminator
      @buffer = String.new
    end

    def readpartial(max_len, out_str = nil)
      res = String.new

      while res.length < max_len
        res << read_chunk(max_len - res.length)
        break if eof? || @nodata
      end

      raise EOFError if res.empty? && eof?

      out_str ||= String.new
      out_str.replace(res)
    end

    def eof?
      @eof
    end

    private

    def slice_safe!(buffer, max_len, terminator, eof)
      safe_len = 0

      safe_len += 1 until terminator.start_with?(buffer[safe_len..]) || safe_len == buffer.length

      safe_len = buffer.length if eof && (safe_len.positive? || terminator.length > buffer.length)

      actual_len = max_len.nil? ? safe_len : [max_len, safe_len].min
      buffer.slice!(0, actual_len)
    end

    def read_chunk(len)
      begin
        read_len = terminator.length - buffer.length
        buffer << (r = stream.readpartial(read_len))
        @nodata = r.length < read_len
      rescue EOFError
        @eof = true
      end

      safe = slice_safe!(buffer, len, terminator, eof?)

      return safe unless safe.empty?

      @eof = true if buffer == terminator

      safe
    end
  end
end
