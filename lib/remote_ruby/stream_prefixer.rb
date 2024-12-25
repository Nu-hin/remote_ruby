module RemoteRuby
  class StreamPrefixer
    attr_reader :stream, :prefix

    def initialize(stream, prefix)
      @stream = stream
      @prefix = prefix
      @buffer = ''
    end

    def read(max_len = nil, out_string = nil)
      out_string ||= ''
      while (line = @stream.readline)
        @buffer << "#{@prefix}#{line}"
        break if max_len && @buffer.length >= max_len
      end
      out_string.replace(@buffer.slice!(0, max_len || @buffer.length))
      out_string
    rescue EOFError
      out_string.replace(@buffer.slice!(0, max_len || @buffer.length))
      out_string
    end
  end
end
