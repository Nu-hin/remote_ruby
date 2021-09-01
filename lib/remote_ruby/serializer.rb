# frozen_string_literal: true

require 'base64'
require 'zlib'
require 'stringio'

module RemoteRuby
  # Provides methods for serialization and deserialization of a hash of (almost)
  # arbitrary Ruby object to GZip-compressed, base64-endoded
  # string
  class Serializer
    def initialize; end

    def serialize(values)
      output = StringIO.new
      gzip = Zlib::GzipWriter.new(output)

      values.each do |name, value|
        bin_val = Marshal.dump(value)
        gzip.puts("#{name}:#{bin_val.size}")
        gzip.write(bin_val)
      end

      gzip.close
      output.close

      Base64.strict_encode64(output.string)
    end

    def deserialize(string)
      input = StringIO.new(Base64.strict_decode64(string))
      gzip = Zlib::GzipReader.new(input)
      res = {}

      until gzip.eof?
        name, size = gzip.readline.split(':')
        bin_val = gzip.read(size.to_i)
        res[name.to_sym] = Marshal.load(bin_val)
      end

      gzip.close
      input.close
      res
    end
  end
end
