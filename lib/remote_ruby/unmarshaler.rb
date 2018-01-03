module RemoteRuby
  # Unmarshals variables from given stream
  class Unmarshaler
    UnmarshalError = Class.new(StandardError)

    def unmarshal(stream, terminator = nil)
      res = {}

      until stream.eof?
        line = stream.readline

        break if terminator && line == terminator

        varname, length = line.split(':')
        length = length.to_i
        data = stream.read(length)

        begin
          res[varname] = Marshal.load(data)
        rescue ArgumentError => e
          raise UnmarshalError, "Could not resolve type for #{varname} variable: #{e.message}"
        end
      end

      res
    end
  end
end
