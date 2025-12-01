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
      execution_context.on_execute_code do |adapter, _|
        expect(adapter).to be_a(RemoteRuby::TmpFileAdapter)
      end

      execution_context.execute({}) do
        # :nocov:
        0
        # :nocov:
      end
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
      execution_context.on_execute_code do |adapter, _|
        expect(adapter).to be_a(RemoteRuby::TextModeAdapter)
      end

      execution_context.execute do
        # :nocov:
        0
        # :nocov:
      end
    end
  end

  context 'with code dumping' do
    let(:base_params) { { dump_code: true } }

    it 'dumps code' do
      code_path = nil

      execution_context.on_execute_code do |_, compiler|
        code_path = File.join(RemoteRuby.code_dir, "#{compiler.code_hash}.rb")
      end

      execution_context.execute({}) do
        # :nocov:
        1 + 1
        # :nocov:
      end

      expect(File).to exist(code_path)
      expect(File.read(code_path)).to include('1 + 1')
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

      execution_context.on_execute_code do |adapter, _|
        expect(adapter).to be_a(RemoteRuby::CacheAdapter)
      end

      execution_context.execute({}) do
        # :nocov:
        10
        # :nocov:
      end
    end
  end

  context 'with cache TTL' do
    let(:base_params) do
      { save_cache: false, use_cache: true, cache_ttl: 30 }
    end

    let(:caching_context) { described_class.new(**params, save_cache: true) }

    context 'when cache is fresh' do
      it 'uses cache' do
        cache_path = nil

        caching_context.on_execute_code do |adapter, _|
          expect(adapter).to be_a(RemoteRuby::CachingAdapter)
          cache_path = adapter.stdout_file_path
        end

        caching_context.execute({}) do
          # :nocov:
          10
          # :nocov:
        end

        expect(cache_path).not_to be_nil
        expect(File).to exist(cache_path)
        File.utime(Time.now - 20, Time.now - 20, cache_path)

        execution_context.on_execute_code do |adapter, _|
          expect(adapter).to be_a(RemoteRuby::CacheAdapter)
        end

        execution_context.execute({}) do
          # :nocov:
          10
          # :nocov:
        end

        expect(File).to exist(cache_path)
      end
    end

    context 'when cache is expired' do
      it 'does not use cache and deletes the files' do
        cache_path = nil

        caching_context.on_execute_code do |adapter, _|
          expect(adapter).to be_a(RemoteRuby::CachingAdapter)
          cache_path = adapter.stdout_file_path
        end

        caching_context.execute({}) do
          # :nocov:
          10
          # :nocov:
        end

        expect(cache_path).not_to be_nil
        expect(File).to exist(cache_path)
        File.utime(Time.now - 60, Time.now - 60, cache_path)

        execution_context.on_execute_code do |adapter, _|
          expect(adapter).to be_a(RemoteRuby::TmpFileAdapter)
        end

        execution_context.execute({}) do
          # :nocov:
          10
          # :nocov:
        end

        expect(File).not_to exist(cache_path)
      end
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
