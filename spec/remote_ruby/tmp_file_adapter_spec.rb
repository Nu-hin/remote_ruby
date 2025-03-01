# frozen_string_literal: true

describe RemoteRuby::TmpFileAdapter do
  subject(:adapter) { described_class.new(**params) }

  let(:params) do
    {
      working_dir: working_dir
    }
  end

  let(:working_dir) do
    File.realpath(Dir.mktmpdir)
  end

  after do
    FileUtils.rm_rf(working_dir)
  end

  it 'runs the script from a file' do
    script = "puts; puts __FILE__\n"
    adapter.open(script) do |_stdin, stdout, _stderr, _result|
      fname = stdout.readpartial(1000).strip
      expect(fname).to match(%r{/remote_ruby})
    end
  end

  it 'reads the input from stdin' do
    input = 'puts gets'
    adapter.open(input) do |stdin, stdout, _stderr, _result|
      stdin.puts 'Hello, world!'
      stdin.close
      expect(stdout.readpartial(1000)).to eq("Hello, world!\n")
    end
  end

  describe '#open' do
    let(:code) { '1 + 1' }
    let(:output_content) { 'output' }
    let(:error_content) { 'error' }
    let(:fake_stdin) { StringIO.new }
    let(:wait_thr) { instance_double(Process::Waiter, value: value) }
    let(:value) { instance_double(Process::Status, success?: success?, to_s: exit_code.to_s) }
    let(:success?) { true }
    let(:exit_code) { 0 }
    let!(:open_double) do
      cd = class_double(Open3)
      allow(cd).to receive(:popen3).and_yield(
        fake_stdin,
        StringIO.new(output_content),
        StringIO.new(error_content),
        wait_thr
      )
      cd.as_stubbed_const
    end

    # rubocop:disable Lint/EmptyBlock
    it 'yields streams' do
      adapter.open(code) do |_stdin, stdout, stderr, _result|
        expect(stdout.readpartial(1000)).to eq(output_content)
        expect(stderr.readpartial(1000)).to eq(error_content)
      end
    end

    it 'calls external command' do
      adapter.open(code) {}
      expect(open_double).to have_received(:popen3).with(%r{ruby.*/remote_ruby})
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
    # rubocop:enable Lint/EmptyBlock
  end
end
