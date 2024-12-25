# frozen_string_literal: true

module RemoteRuby
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
        res << readpartial(max_len.nil? ? nil : max_len - res.length)
        break if !max_len.nil? && res.length >= max_len
      rescue EOFError
        break
      end

      out_str ||= String.new
      out_str.replace(res)
    end

    def readpartial(max_len = nil, out_string = nil)
      out_string ||= String.new

      loop do
        unless @out_buffer.empty?
          if max_len.nil? || @out_buffer.length <= max_len
            out_string.replace(@out_buffer)
            @out_buffer.clear
          else
            res = @out_buffer[0..max_len - 1]
            @out_buffer = @out_buffer[max_len..]
            out_string.replace(res)
          end

          return out_string
        end

        raise EOFError if @eof

        begin
          read = stream.readpartial(max_len)
        rescue EOFError
          @eof = true
          raise EOFError if @out_buffer.empty?
        end

        if read.empty?
          @eof = true
          raise EOFError if @out_buffer.empty?
        end

        read.each_line do |line|
          @out_buffer << prefix if @prefix_needed
          @prefix_needed = line.end_with?("\n")
          @out_buffer << line
        end
      end

      out_string.replace(res)
      out_string
    end
  end
end
