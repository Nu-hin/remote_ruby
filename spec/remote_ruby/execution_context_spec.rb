# frozen_string_literal: true

require 'tmpdir'

describe RemoteRuby::ExecutionContext do
  subject(:execution_context) do
    described_class.new(**params)
  end

  let(:working_dir) { Dir.mktmpdir }
  let(:remote_context) do
    RemoteRuby::RemoteContext.new('rr.rb').dump
  end

  let(:base_params) { {} }
  let(:params) do
    {
      working_dir: working_dir
    }.merge(base_params)
  end

  before do
    RemoteRuby.configure do |c|
      c.cache_dir = Dir.mktmpdir
      c.code_dir = Dir.mktmpdir
    end
  end

  after do
    RemoteRuby.clear_cache
    RemoteRuby.clear_code
    FileUtils.rm_rf(working_dir)
  end

  context 'when host is set' do
    let(:base_params) { { host: 'some_host' } }

    it 'uses SSH adapter' do
      adapter = instance_double(RemoteRuby::SSHAdapter)
      stub = class_double(RemoteRuby::SSHAdapter, new: adapter).as_stubbed_const
      allow(adapter).to receive(:open).and_return(remote_context)

      execution_context.execute({}) do
        # :nocov:
        0
        # :nocov:
      end

      expect(stub).to have_received(:new)
      expect(adapter).to have_received(:open)
    end
  end

  context 'when host is not set' do
    it 'uses TmpFile adapter' do
      adapter = instance_double(RemoteRuby::TmpFileAdapter)
      stub = class_double(RemoteRuby::TmpFileAdapter, new: adapter).as_stubbed_const
      allow(adapter).to receive(:open).and_return(remote_context)

      execution_context.execute({}) do
        # :nocov:
        0
        # :nocov:
      end

      expect(stub).to have_received(:new)
      expect(adapter).to have_received(:open)
    end
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
      # :nocov:
      var = File.read(fname)
      var
      # :nocov:
    end

    expect(res).to eq(File.read(fname))
    expect(res).to eq(var)
  end

  context 'with save_cache' do
    let(:base_params) { { save_cache: true } }

    it 'creates cache files' do
      execution_context.execute do
        # :nocov:
        0
        # :nocov:
      end

      expect(Dir.glob(File.join(RemoteRuby.cache_dir, '*'))).not_to be_empty
    end
  end

  context 'with text_mode' do
    let(:base_params) { { text_mode: { disable_unless_tty: false } } }

    it 'uses TextMode adapter' do
      allow(RemoteRuby::TextModeAdapter).to receive(:new).and_call_original

      execution_context.execute do
        # :nocov:
        0
        # :nocov:
      end

      expect(RemoteRuby::TextModeAdapter)
        .to have_received(:new)
        .with(instance_of(RemoteRuby::TmpFileAdapter),
              include(
                stdout_mode: { color: :green, mode: :italic },
                stderr_mode: { color: :red, mode: :italic }
              ))
    end
  end

  context 'with code dumping' do
    let(:base_params) { { dump_code: true } }

    it 'dumps code' do
      execution_context.execute do
        # :nocov:
        1 + 1
        # :nocov:
      end

      expect(Dir.glob(File.join(RemoteRuby.code_dir, '*.rb'))).not_to be_empty
    end
  end

  context 'with use_cache' do
    let(:base_params) do
      { save_cache: true, use_cache: true }
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
      allow(cache_adapter).to receive(:open).and_return(remote_context)
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

  context 'when local variable type is ignored' do
    it 'does not serialize it' do
      var = Class.new.new

      RemoteRuby.ignore_types(var.class)

      res = execution_context.execute do
        # :nocov:
        defined?(var)
        # :nocov:
      end

      expect(res).to be_falsey
    end
  end

  context 'when remote code raises an exception' do
    it 'raises an exception' do
      data = nil
      a = 1
      b = 2
      expect do
        data = execution_context.execute do
          # :nocov:
          a = 10
          raise 'Error'
          b = 20 # rubocop:disable Lint/UnreachableCode
          30
          # :nocov:
        end
      end.to raise_error(RemoteRuby::RemoteError)

      expect(a).to eq(10)
      expect(b).to eq(2)
      expect(data).to be_nil
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
