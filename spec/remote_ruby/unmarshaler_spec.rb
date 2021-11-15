# frozen_string_literal: true

describe ::RemoteRuby::Unmarshaler do
  subject(:result) { described_class.new(source_stream).unmarshal }

  let(:source_stream) { StringIO.new }

  def dump(name, value)
    data = Marshal.dump(value)
    source_stream.puts("#{name}:#{data.length}")
    source_stream.write(data)
  end

  context 'when all data can be deserialized' do
    let(:str_value) { 'string data' }
    let(:int_value) { 42 }
    let(:array_value) { [str_value, int_value] }
    let(:hash_value) { { str_value => int_value } }

    before(:example) do
      dump('str_value', str_value)
      dump('int_value', int_value)
      dump('array_value', array_value)
      dump('hash_value', hash_value)
      source_stream.close_write
      source_stream.rewind
    end

    it 'successfully deserializes all data' do
      expect(result).to match(
        str_value: str_value,
        int_value: int_value,
        array_value: array_value,
        hash_value: hash_value
      )
    end
  end

  context 'when data can not be deserialized' do
    context 'because constant cannot be resolved' do
      class UnknownClass
        def initialize(val)
          @val = val
        end
      end

      before(:example) do
        class_val = UnknownClass.new(10)
        dump('class_val', class_val)
        source_stream.close_write
        source_stream.rewind
        Object.send(:remove_const, :UnknownClass)
      end

      it 'raises an UnmarshalError' do
        expect { result }.to(
          raise_error ::RemoteRuby::Unmarshaler::UnmarshalError
        )
      end
    end

    context 'because of incorrect data' do
      it 'raises an error on wrong format' do
        source_stream.write('Some data in an incorrect format')
        source_stream.close_write
        source_stream.rewind

        expect { result }.to(
          raise_error ::RemoteRuby::Unmarshaler::UnmarshalError
        )
      end

      it 'raises an error on wrong header' do
        source_stream.write([10, 43])
        source_stream.close_write
        source_stream.rewind

        expect { result }.to(
          raise_error ::RemoteRuby::Unmarshaler::UnmarshalError
        )
      end

      it 'raises ummarshaling error' do
        source_stream.puts('mbon:12')
        source_stream.write([10, 43])
        source_stream.close_write
        source_stream.rewind

        expect { result }.to(
          raise_error ::RemoteRuby::Unmarshaler::UnmarshalError
        )
      end
    end
  end
end
