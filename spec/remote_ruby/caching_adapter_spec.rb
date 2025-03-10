# frozen_string_literal: true

describe RemoteRuby::CachingAdapter do
  subject(:adapter) do
    described_class.new(
      adapter: base_adapter,
      cache_path: cache_path
    )
  end

  let(:base_adapter) { TestAdapter.new(out: 'OUT', err: 'ERROR', result: 'RESULT') }

  let(:cache_path) do
    File.join(Dir.mktmpdir, 'test')
  end

  let(:stdout_cache_path) do
    "#{cache_path}.stdout"
  end

  let(:stderr_cache_path) do
    "#{cache_path}.stderr"
  end

  let(:result_cache_path) do
    "#{cache_path}.result"
  end

  after do
    FileUtils.rm_rf(cache_path)
  end

  describe '#connection_name' do
    it 'proxies call to base adapter' do
      expect(adapter.connection_name).to eq(base_adapter.connection_name)
    end
  end

  describe '#open' do
    def run(code)
      stdout = StringIO.new
      stderr = StringIO.new
      res = adapter.open(code, nil, stdout, stderr)
      stdout.close
      stderr.close
      [stdout.string, stderr.string, res]
    end

    it 'saves standard output to a file' do
      run('exit')
      expect(File.read(stdout_cache_path)).to eq('OUT')
    end

    it 'saves standard error to a file' do
      run('exit')
      expect(File.read(stderr_cache_path)).to eq('ERROR')
    end

    it 'saves result to a file' do
      run('exit')
      expect(File.read(result_cache_path)).to eq('RESULT')
    end

    it 'proxies call to base adapter' do
      allow(base_adapter).to receive(:open)

      code = 'exit'

      run(code)
      expect(base_adapter).to have_received(:open).with(code, nil, instance_of(RemoteRuby::TeeWriter),
                                                        instance_of(RemoteRuby::TeeWriter))
    end
  end
end
