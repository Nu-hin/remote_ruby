describe ::RemoteRuby::SSHStdinAdapter do
  subject(:adapter) { described_class.new(params) }

  let(:working_dir) { '/var/ruby_project' }
  let(:server) { 'ssh_host' }
  let(:username) { 'dev' }
  let(:key_file) { '/home/dev/.ssh/special_key' }

  let(:params) do
    {
      working_dir: working_dir,
      server: server,
      user: username,
      key_file: key_file
    }
  end

  describe '#connection_name' do
    it 'includes host name and dir' do
      expect(adapter.connection_name).to(
        eq("#{username}@#{server}:#{working_dir}")
      )
    end
  end

  describe '#open' do
    let(:code) { '1 + 1' }
    let(:output_content) { 'output' }
    let(:error_content) { 'error' }
    let(:fake_stdin) { StringIO.new }
    let(:wait_thr) { double(:wait_thr, value: value) }
    let(:value) { double(:value, success?: success?, to_s: exit_code.to_s) }
    let(:success?) { true }
    let(:exit_code) { 0 }

    before(:example) do
      allow(adapter).to receive(:popen3).and_yield(
        fake_stdin,
        StringIO.new(output_content),
        StringIO.new(error_content),
        wait_thr
      )
    end

    it 'writes code to stdin' do
      adapter.open(code) {}
      expect(fake_stdin.string).to eq(code)
    end

    it 'yields streams' do
      adapter.open(code) do |stdout, stderr|
        expect(stdout.read).to eq(output_content)
        expect(stderr.read).to eq(error_content)
      end
    end

    it 'calls ssh command' do
      expect(adapter).to receive(:popen3).with(
        "ssh -i #{key_file} #{username}@#{server} \"cd #{working_dir} && ruby\""
      )
      adapter.open(code) {}
    end

    context 'when process fails' do
      let(:success?) { false }
      let(:exit_code) { 127 }

      it 'raises error' do
        expect do
          adapter.open(code) {}
        end.to raise_error(RuntimeError, Regexp.new(value.to_s))
      end
    end
  end
end
