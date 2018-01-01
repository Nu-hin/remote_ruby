require 'tmpdir'

describe ::Rubyremote::ExecutionContext do
  subject(:execution_context) do
    described_class.new(**params)
  end

  let(:working_dir) do
    Dir.mktmpdir
  end

  let(:cache_dir) do
    Dir.mktmpdir
  end

  after(:each) do
    FileUtils.rm_rf(working_dir)
    FileUtils.rm_rf(cache_dir)
  end

  let(:base_params) { {} }
  let(:params) do
    {
      adapter: :local_stdin,
      working_dir: working_dir
    }.merge(base_params)
  end

  it 'prints to stdout' do
    s = 'Something'

    expect do
      execution_context.execute(s: s) do
        puts s
      end
    end.to output(Regexp.new(s)).to_stdout
  end

  context 'with save_cache' do
    let(:base_params) { { save_cache: true, cache_dir: cache_dir } }

    it 'creates cache files' do
      execution_context.execute do
        puts 'Something'
      end

      expect(Dir.glob(File.join(cache_dir, '*'))).not_to be_empty
    end
  end
end
