# frozen_string_literal: true

require 'tmpdir'

describe RemoteRuby::ExecutionContext do
  subject(:execution_context) do
    described_class.new(**params)
  end

  let(:working_dir) do
    Dir.mktmpdir
  end
  let(:base_params) { {} }
  let(:params) do
    {
      adapter: RemoteRuby::TmpFileAdapter,
      working_dir: working_dir
    }.merge(base_params)
  end

  let(:cache_dir) do
    Dir.mktmpdir
  end

  after do
    FileUtils.rm_rf(working_dir)
    FileUtils.rm_rf(cache_dir)
  end

  it 'prints to stdout' do
    s = 'Something'

    expect do
      execution_context.execute(s: s) do
        # :nocov:
        puts s
        # :nocov:
      end
    end.to output("#{s}\n").to_stdout
  end

  it 'serializes binary data correctly' do
    fname = File.join(__dir__, '../support/test_files/noise.png')
    var = nil

    res = execution_context.execute(fname: fname, var: var) do
      var = File.read(fname)
      var
    end

    expect(res).to eq(File.read(fname))
    expect(res).to eq(var)
  end

  context 'with save_cache' do
    let(:base_params) { { save_cache: true, cache_dir: cache_dir } }

    it 'creates cache files' do
      execution_context.execute do
        # :nocov:
        0
        # :nocov:
      end

      expect(Dir.glob(File.join(cache_dir, '*'))).not_to be_empty
    end
  end

  context 'with use_cache' do
    let(:base_params) do
      { save_cache: true, use_cache: true, cache_dir: cache_dir }
    end

    let(:caching_context) { described_class.new(**params) }

    it 'uses cache' do
      caching_context.execute({}) do
        # :nocov:
        10
        # :nocov:
      end

      cache_adapter_class = class_double(RemoteRuby::CacheAdapter, :new)
      cache_adapter = instance_double(RemoteRuby::CacheAdapter)
      allow(cache_adapter_class).to receive(:new).and_return(cache_adapter)
      allow(cache_adapter).to receive(:open).and_yield(nil, StringIO.new, StringIO.new, StringIO.new)
      cache_adapter_class.as_stubbed_const

      execution_context.execute({}) do
        # :nocov:
        10
        # :nocov:
      end

      expect(cache_adapter_class).to have_received(:new)
      expect(cache_adapter).to have_received(:open)
    end
  end

  context 'when execution context is a local variable' do
    it 'does not serialize it' do
      ec = execution_context

      res = ec.execute do
        # :nocov:
        defined?(ec)
        # :nocov:
      end

      expect(res).to be_falsey
    end
  end

  context 'with Rails plugin' do
    let(:base_params) do
      {
        rails: { environment: :production }
      }
    end

    before do
      path = File.join(working_dir, 'config/environment.rb')
      dirname = File.dirname(path)
      Dir.mkdir(dirname)
      File.write(path, "ENV['RAILS_ENV']")
    end

    it 'includes Rails loading code' do
      res = execution_context.execute do
        # :nocov:
        ENV.fetch('RAILS_ENV', nil)
        # :nocov:
      end

      expect(res).to eq('production')
    end
  end

  context 'with stream redirection' do
    let(:err_str) { StringIO.new }
    let(:out_str) { StringIO.new }

    let(:base_params) do
      {
        out_stream: out_str,
        err_stream: err_str
      }
    end

    it 'redirects stdout to the specified stream' do
      execution_context.execute do
        # :nocov:
        puts 'Hello'
        # :nocov:
      end

      expect(out_str.string).to eq("Hello\n")
    end

    it 'redirects stderr to the specified stream' do
      execution_context.execute do
        # :nocov:
        warn 'Error'
        # :nocov:
      end

      expect(err_str.string).to eq("Error\n")
    end
  end
end
