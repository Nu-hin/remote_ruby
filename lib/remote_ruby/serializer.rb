# frozen_string_literal: true

require 'base64'
require 'zlib'
require 'stringio'

module RemoteRuby
  # Provides methods for serialization and deserialization of (almost)
  # arbitrary Ruby object to GZip-compressed, base64-endoded
  # string
  class Serializer
    def self.serialize(value)
      output = StringIO.new
      stream = Zlib::GzipWriter.new(output)
      Marshal.dump(value, stream)
      stream.close
      output.close

      Base64.strict_encode64(output.string)
    end

    def self.deserialize(string)
      input = StringIO.new(Base64.strict_decode64(string))
      stream = Zlib::GzipReader.new(input)
      result = Marshal.load(stream)
      stream.close
      input.close
      result
    end
  end
end
