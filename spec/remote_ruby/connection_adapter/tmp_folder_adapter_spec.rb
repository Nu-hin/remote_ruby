# frozen_string_literal: true

describe RemoteRuby::TmpFolderAdapter do
  subject(:adapter) { described_class.new(**params) }

  let(:bundler) { false }

  let(:params) do
    {
      working_dir: working_dir,
      bundler: bundler
    }
  end

  let(:working_dir) do
    File.realpath(Dir.mktmpdir)
  end

  after(:each) do
    FileUtils.rm_rf(working_dir)
  end

  it 'runs the script from a file' do
    script = "puts __FILE__\n"
    adapter.open(script) do |_stdin, stdout, _stderr|
      fname = stdout.read.strip
      expect(fname).to match(%r{/remote_ruby\.rb$})
    end
  end

  it 'reads the input from stdin' do
    input = 'puts gets'
    adapter.open(input) do |stdin, stdout, _stderr|
      stdin.puts 'Hello, world!'
      stdin.close
      expect(stdout.read).to eq("Hello, world!\n")
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
    let(:bundler) { false }

    before(:example) do
      allow(adapter).to receive(:popen3).and_yield(
        fake_stdin,
        StringIO.new(output_content),
        StringIO.new(error_content),
        wait_thr
      )
    end

    # rubocop:disable Lint/EmptyBlock
    it 'yields streams' do
      adapter.open(code) do |_stdin, stdout, stderr|
        expect(stdout.read).to eq(output_content)
        expect(stderr.read).to eq(error_content)
      end
    end

    it 'calls external command' do
      allow(adapter).to receive(:command).and_return('echo')
      expect(adapter).to receive(:popen3).with('echo')
      adapter.open(code) {}
    end

    context 'with bundler' do
      let(:bundler) { true }

      it 'includes bundle exec to the command' do
        expect(adapter).to receive(:popen3).with(match(/bundle exec/))
        adapter.open(code) {}
      end
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
