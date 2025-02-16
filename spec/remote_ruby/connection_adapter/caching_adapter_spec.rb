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

  let(:result_cache_path) do
    "#{cache_path}.result"
  end

  after do
    FileUtils.rm_rf(cache_path)
  end

  describe '#open' do
    def run(code)
      adapter.open(code) do |_stdin, stdout, stderr, result|
        stdout.read
        stderr.read
        result.read
      end
    end

    it 'saves standard output to a file' do
      run("puts; print 'text'")
      expect(File.read(stdout_cache_path)).to eq("\ntext")
    end

    it 'saves standard error to a file' do
      run("puts; $stderr.print 'text'")
      expect(File.read(stderr_cache_path)).to eq('text')
    end

    it 'saves result to a file' do
      run('print "%%%MARSHAL\nTEST"')
      expect(File.read(result_cache_path)).to eq('TEST')
    end

    it 'proxies call to base adapter' do
      code = '1 + 1'
      expect(base_adapter).to receive(:open).with(code)
      run(code)
    end
  end
end
