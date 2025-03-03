# frozen_string_literal: true

describe RemoteRuby::CacheAdapter do
  subject(:adapter) do
    described_class.new(
      cache_path: cache_path,
      connection_name: 'conn'
    )
  end

  let(:output) { 'output' }
  let(:errors) { 'errors' }

  let(:cache_path) do
    cache_path = File.join(Dir.mktmpdir, 'test')

    File.binwrite("#{cache_path}.stdout", output)
    File.binwrite("#{cache_path}.stderr", errors)

    cache_path
  end

  after do
    FileUtils.rm_rf(cache_path)
  end

  describe '#open' do
    it 'reads stdout from cache' do
      stdout = StringIO.new
      stderr = StringIO.new

      adapter.open(nil, nil, stdout, stderr)

      [stdout, stderr].each(&:close)

      expect(stdout.string).to eq(output)
    end

    it 'reads stderr from cache' do
      stdout = StringIO.new
      stderr = StringIO.new

      adapter.open(nil, nil, stdout, stderr)

      [stdout, stderr].each(&:close)

      expect(stderr.string).to eq(errors)
    end
  end
end
