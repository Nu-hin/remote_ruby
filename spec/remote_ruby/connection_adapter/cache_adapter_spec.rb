# frozen_string_literal: true

describe RemoteRuby::CacheAdapter do
  subject(:adapter) do
    described_class.new(
      cache_path: cache_path
    )
  end

  let(:output) { 'output' }
  let(:errors) { 'errors' }

  let(:cache_path) do
    cache_path = File.join(Dir.mktmpdir, 'test')

    File.binwrite("#{cache_path}.stdout", output)
    File.binwrite("#{cache_path}.stderr", output)

    cache_path
  end

  after(:each) do
    FileUtils.rm_rf(cache_path)
  end

  describe '#open' do
    it 'reads stdout from cache' do
      adapter.open(nil) do |_stdin, stdout, _stderr|
        expect(stdout.read).to eq(output)
      end
    end

    it 'reads stderr from cache' do
      adapter.open(nil) do |_stdin, _stdout, stderr|
        expect(stderr.read).to eq(output)
      end
    end
  end
end
