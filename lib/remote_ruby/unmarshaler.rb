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
        line = stream.readline

        break if terminator && line == terminator

        var = read_var(line)
        res[var.first] = var[1]
      end

      res
    end

    private

    attr_reader :stream, :terminator

    def read_var(line)
      varname, length = read_var_header(line)
      data = read_var_data(length)
      [varname.to_sym, data]
    rescue ArgumentError => e
      raise UnmarshalError,
            "Could not resolve type for #{varname} variable: #{e.message}"
    rescue TypeError
      raise UnmarshalError, 'Incorrect data format'
    end

    def read_var_header(line)
      varname, length = line.split(':')

      if varname.nil? || length.nil?
        raise UnmarshalError, "Incorrect header '#{line}'"
      end

      [varname, length]
    end

    # rubocop:disable Security/MarshalLoad
    def read_var_data(length)
      data = stream.read(length.to_i)
      Marshal.load(data)
    end
    # rubocop:enable Security/MarshalLoad
  end
end
