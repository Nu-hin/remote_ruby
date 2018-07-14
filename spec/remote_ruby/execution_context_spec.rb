require 'tmpdir'

describe ::RemoteRuby::ExecutionContext do
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
      adapter: ::RemoteRuby::LocalStdinAdapter,
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

  context 'when execution context is a local variable' do
    it 'does not serialize it' do
      ec = execution_context

      res = ec.execute do
        defined?(ec)
      end

      expect(res).to be_falsey
    end
  end

  context 'with Rails flavour' do
    let(:base_params) do
      {
        rails: { environment: :production }
      }
    end

    before(:example) do
      path = File.join(working_dir, 'config/environment.rb')
      dirname = File.dirname(path)
      Dir.mkdir(dirname)
      File.write(path, "ENV['RAILS_ENV']")
    end

    it 'includes Rails loading code' do
      res = execution_context.execute do
        ENV['RAILS_ENV']
      end

      expect(res).to eq('production')
    end
  end

  context 'with stream redirection' do
    let(:err_str) { StringIO.new('') }
    let(:out_str) { StringIO.new('') }

    let(:base_params) do
      {
        stdout: out_str,
        stderr: err_str
      }
    end

    it 'redirects stdout to the specified stream' do
      execution_context.execute do
        puts 'Hello'
      end

      expect(out_str.string).to include('Hello')
    end

    it 'redirects stderr to the specified stream' do
      execution_context.execute do
        warn 'Error'
      end

      expect(err_str.string).to include('Error')
    end
  end
end
