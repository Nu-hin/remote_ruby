# frozen_string_literal: true

describe RemoteRuby::CachingAdapter do
  subject(:adapter) do
    described_class.new(
      adapter: base_adapter,
      cache_path: cache_path
    )
  end

  let(:base_adapter) { RemoteRuby::EvalAdapter.new }

  let(:cache_path) do
    File.join(Dir.mktmpdir, 'test')
  end

  let(:stdout_cache_path) do
    "#{cache_path}.stdout"
  end

  let(:stderr_cache_path) do
    "#{cache_path}.stderr"
  end

  after(:each) do
    FileUtils.rm_rf(cache_path)
  end

  describe '#open' do
    def run(code)
      adapter.open(code) do |_stdin, stdout, stderr|
        stdout.read
        stderr.read
      end
    end

    it 'saves output to file' do
      run("puts; print 'text'")
      expect(File.read(stdout_cache_path)).to eq('text')
    end

    it 'saved errors to file' do
      run("puts; $stderr.print 'text'")
      expect(File.read(stderr_cache_path)).to eq('text')
    end

    it 'proxies call to base adapter' do
      code = '1 + 1'
      expect(base_adapter).to receive(:open).with(code)
      run(code)
    end
  end
end
