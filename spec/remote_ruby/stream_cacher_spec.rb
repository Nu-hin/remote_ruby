# frozen_string_literal: true

describe RemoteRuby::StreamCacher do
  subject(:cacher) { described_class.new(input_stream, cache_stream) }
  let(:cache_stream) { StringIO.new }
  let(:input_stream) { StringIO.new(source_string) }
  let(:source_string) { "a\na\na\n" }

  describe '#read' do
    context 'without arguments' do
      it 'reads the whole string' do
        expect(cacher.read).to eq(source_string)
      end

      it 'caches read string' do
        cacher.read
        expect(cache_stream.string).to eq(source_string)
      end
    end

    context 'when number is specified' do
      it 'reads specified amount of data' do
        expect(cacher.read(2)).to eq(source_string[0..1])
      end

      it 'caches read data' do
        cacher.read(2)
        expect(cache_stream.string).to eq(source_string[0..1])
      end
    end
  end

  describe '#readline' do
    it 'reads one line' do
      expect(cacher.readline).to eq(source_string[0..1])
    end

    it 'caches read data' do
      cacher.readline
      expect(cache_stream.string).to eq(source_string[0..1])
    end
  end

  describe '#eof?' do
    it 'returns true when source stream is at end' do
      input_stream.read
      expect(cacher.eof?).to be_truthy
    end

    it 'returns false when source stream is not at end' do
      input_stream.read(3)
      expect(cacher.eof?).to be_falsey
    end
  end

  describe '#close' do
    it 'closes the source stream' do
      cacher.close
      expect(input_stream).to be_closed
    end

    it 'does not close cache stream' do
      cacher.close
      expect(cache_stream).not_to be_closed
    end
  end
end
