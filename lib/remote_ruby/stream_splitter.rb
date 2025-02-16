# frozen_string_literal: true

module RemoteRuby
  # Implements a reader. Receives a steram and a terminator.
  # Reads from the stream until the terminator is found.
  class StreamSplitter
    attr_reader :stream, :terminator
    attr_accessor :buffer

    def initialize(stream, terminator)
      @stream = stream
      @eof = false
      @terminator = terminator
      @buffer = String.new
    end

    def read(max_len = nil, out_str = nil)
      res = String.new

      loop do
        if max_len.nil?
          res << readpartial
        else
          res << readpartial(max_len - res.length)
          break if res.length >= max_len
        end
      rescue EOFError
        break
      end

      out_str ||= String.new
      out_str.replace(res)
    end

    def readpartial(max_len = nil, out_str = nil)
      out_str ||= String.new

      loop do
        raise EOFError if @eof && buffer.empty?

        res, self.buffer = separate_prefix(buffer)

        unless res.empty?
          return out_str.replace(res) if max_len.nil? || res.length <= max_len

          rem = res[max_len..]
          self.buffer = "#{rem}#{buffer}"

          return out_str.replace(res[0..max_len - 1])
        end

        if buffer == terminator
          @eof = true
          self.buffer = ''
          raise EOFError
        elsif @eof
          if max_len.nil? || buffer.length <= max_len
            res = buffer
            self.buffer = ''
            return out_str.replace(res)
          end

          res = buffer[0..max_len - 1]
          self.buffer = buffer[max_len..]
          return out_str.replace(res)
        else
          begin
            read = stream.readpartial(terminator.length - buffer.length)
            self.buffer = "#{buffer}#{read}"
          rescue EOFError
            @eof = true
            raise EOFError if buffer.empty?
          end
        end
      end
    end

    def eof?
      @eof
    end

    # Returns the longest prefix of the string that
    # is not a prefix of the terminator.
    def separate_prefix(str)
      return [nil, nil] if str.nil?
      return [String.new, String.new] if str.empty?

      i = 0
      j = 0

      until i >= str.length
        i += 1
        if terminator[j] == str[i - 1]
          j += 1

          if j == terminator.length || i == str.length
            i -= j

            return [String.new, str] if i.zero?

            return [str[0..i - 1], str[i..]]

          end
        else
          j = 0
        end
      end

      [str, String.new]
    end
  end
end
