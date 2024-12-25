# frozen_string_literal: true

RSpec.describe RemoteRuby::StreamPrefixer do
  let(:stream) { StringIO.new("line1\nline2\nline3\n") }
  let(:prefix) { 'PREFIX: ' }
  subject(:stream_prefixer) { described_class.new(stream, prefix) }

  describe '#initialize' do
    it 'initializes with a stream and a prefix' do
      expect(stream_prefixer.stream).to eq(stream)
      expect(stream_prefixer.prefix).to eq(prefix)
    end
  end

  describe '#readpartial' do
    context 'when reading without max_len' do
      it 'reads and prefixes lines from the stream' do
        result = stream_prefixer.readpartial
        expect(result).to eq("PREFIX: line1\nPREFIX: line2\nPREFIX: line3\n")
      end
    end

    context 'when reading with max_len' do
      it 'reads and prefixes lines up to max_len' do
        result = stream_prefixer.readpartial(10)
        expect(result).to eq('PREFIX: li')
      end

      it 'continues reading from the buffer on subsequent reads' do
        stream_prefixer.readpartial(10)
        result = stream_prefixer.readpartial(10)
        expect(result).to eq("ne1\nPREFIX")
      end
    end

    context 'when reaching EOF' do
      it 'reads remaining buffer when EOF is reached' do
        stream_prefixer.readpartial(30)
        result = stream_prefixer.readpartial(100)
        expect(result).to eq("EFIX: line3\n")
      end
    end
  end
end
