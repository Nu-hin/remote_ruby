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

    def read(max_len = nil, out_str = nil)
      res = String.new

      loop do
        res << readpartial(max_len.nil? ? nil : max_len - res.length)
        break if !max_len.nil? && res.length >= max_len
      rescue EOFError
        break
      end

      out_str ||= String.new
      out_str.replace(res)
    end

    def readpartial(max_len, out_str = nil)
      out_str ||= String.new
      out_str.replace(readpartial_direct(max_len))
    end

    def eof?
      @eof
    end

    def slice_safe!(buffer, max_len, terminator, eof)
      safe_len = 0

      safe_len += 1 until terminator.start_with?(buffer[safe_len..]) || safe_len == buffer.length

      safe_len = buffer.length if eof && (safe_len.positive? || terminator.length > buffer.length)

      actual_len = max_len.nil? ? safe_len : [max_len, safe_len].min
      buffer.slice!(0, actual_len)
    end

    private

    def read_chunk(len)
      begin
        buffer << stream.readpartial(terminator.length - buffer.length)
      rescue EOFError
        @eof = true
      end

      safe = slice_safe!(buffer, len, terminator, eof?)

      return safe unless safe.empty?

      @eof = true if eof? || buffer == terminator

      safe
    end

    def readpartial_direct(max_len)
      res = String.new

      while res.length < max_len
        read_len = max_len - res.length
        res << read_chunk(read_len)
        break if eof?
      end

      raise EOFError if res.empty?

      res
    end
  end
end
