# frozen_string_literal: true

describe ::RemoteRuby::CacheAdapter do
  subject(:adapter) do
    described_class.new(
      connection_name: connection_name,
      cache_path: cache_path
    )
  end

  let(:connection_name) { 'test' }
  let(:output) { 'output' }
  let(:errors) { 'errors' }

  let(:cache_path) do
    cache_path = File.join(Dir.mktmpdir, 'test')

    File.open("#{cache_path}.stdout", 'wb') do |f|
      f.write(output)
    end
    File.open("#{cache_path}.stderr", 'wb') do |f|
      f.write(output)
    end

    cache_path
  end

  after(:each) do
    FileUtils.rm_rf(cache_path)
  end

  describe '#connection_name' do
    it 'adds [CACHE] prefix' do
      expect(adapter.connection_name).to eq("[CACHE] #{connection_name}")
    end
  end

  describe '#open' do
    it 'reads stdout from cache' do
      adapter.open(nil) do |stdout|
        expect(stdout.read).to eq(output)
      end
    end

    it 'reads stderr from cache' do
      adapter.open(nil) do |_, stderr|
        expect(stderr.read).to eq(output)
      end
    end
  end
end
