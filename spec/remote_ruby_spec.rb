RSpec.describe RemoteRuby do
  describe '.remotely' do
    let(:working_dir) do
      Dir.mktmpdir
    end

    after(:each) do
      FileUtils.rm_rf(working_dir)
    end

    let(:args) do
      {
        adapter: ::RemoteRuby::EvalAdapter,
        working_dir: working_dir
      }
    end

    it 'proxies call to ExecutionContext' do
      expect(RemoteRuby::ExecutionContext).to receive(:new)
        .with(**args).and_return(double(:ec, execute: nil))

      remotely(**args) do
        puts 'Hello RemoteRuby'
      end
    end

    it 'returns block result' do
      res = remotely(**args) do
        { username: 'John' }
      end

      expect(res).to eq(username: 'John')
    end

    it 'changes local variables' do
      a = 3

      remotely(**args) do
        a = 4
      end

      expect(a).to eq(4)
    end
  end
end
