module Rubyremote
  class Unmarshaler
    UnmarshalError = Class.new(StandardError)

    def unmarshal(stream, terminator = nil)
      res = {}

      until stream.eof?
        line = stream.readline

        if terminator && line == terminator
          break
        end

        varname, length = line.split(':')
        length = length.to_i
        data = stream.read(length)

        begin
          res[varname] = Marshal.load(data)
        rescue ArgumentError => e
          fail UnmarshalError, "Could not resolve type for #{varname} variable: #{e.message}"
        end
      end

      res
    end
  end
end
