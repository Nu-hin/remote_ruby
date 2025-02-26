# frozen_string_literal: true

RSpec.describe RemoteRuby do
  describe '.configure' do
    it 'yields itself' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(described_class)
    end
  end

  describe '.remotely' do
    let(:working_dir) do
      Dir.mktmpdir
    end
    let(:args) do
      {
        adapter: RemoteRuby::TmpFileAdapter,
        working_dir: working_dir
      }
    end

    after do
      FileUtils.rm_rf(working_dir)
    end

    it 'proxies call to ExecutionContext' do
      allow(RemoteRuby::ExecutionContext).to receive(:new)
        .with(**args).and_return(instance_double(RemoteRuby::ExecutionContext, execute: nil))

      remotely(**args) do
        # :nocov:
        puts 'Hello RemoteRuby'
        # :nocov:
      end

      expect(RemoteRuby::ExecutionContext).to have_received(:new)
    end

    it 'returns block result' do
      res = remotely(**args) do
        # :nocov:
        { username: 'John' }
        # :nocov:
      end

      expect(res).to eq(username: 'John')
    end

    it 'changes local variables' do
      a = 3

      remotely(**args) do
        # :nocov:
        a = 4
        # :nocov:
      end

      expect(a).to eq(4)
    end
  end
end
