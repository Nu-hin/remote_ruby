module RemoteRuby
  # Unmarshals variables from given stream
  class Unmarshaler
    UnmarshalError = Class.new(StandardError)

    def initialize(stream, terminator = nil)
      @stream = stream
      @terminator = terminator
    end

    def unmarshal
      res = {}

      until stream.eof?
        var = read_var
        break if var.nil?
        res[var.first] = var[1]
      end

      res
    end

    private

    attr_reader :stream, :terminator

    def read_var
      line = stream.readline
      return nil if terminator && line == terminator

      varname, length = line.split(':')
      data = stream.read(length.to_i)
      [varname.to_sym, Marshal.load(data)]
    rescue ArgumentError => e
      raise UnmarshalError,
            "Could not resolve type for #{varname} variable: #{e.message}"
    end
  end
end
