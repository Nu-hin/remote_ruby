# frozen_string_literal: true

RSpec.describe RemoteRuby::StreamPrefixer do
  subject(:stream_prefixer) { described_class.new(stream, prefix) }

  let(:stream) { StringIO.new("line1\nline2\nline3\n") }
  let(:prefix) { 'PREFIX: ' }

  describe '#initialize' do
    it 'initializes with a stream and a prefix' do
      expect(stream_prefixer.stream).to eq(stream)
      expect(stream_prefixer.prefix).to eq(prefix)
    end
  end

  describe '#readpartial' do
    context 'when EOF is not reached' do
      let(:pipe) { IO.pipe }
      let(:stream) { pipe.first }
      let(:writer) { pipe.last }

      it 'reads and prefixes lines from the stream' do
        writer.puts('line1')

        result = stream_prefixer.readpartial(1024)
        expect(result).to eq("PREFIX: line1\n")
        writer.close
      end
    end

    context 'when reading without max_len' do
      it 'reads and prefixes lines from the stream' do
        result = stream_prefixer.readpartial(1000)
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
        expect { stream_prefixer.readpartial(100) }.to raise_error(EOFError)
      end
    end
  end
end
