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
    script = 'puts __FILE__'
    stdout = StringIO.new
    stderr = StringIO.new
    adapter.open(script, StringIO.new, stdout, stderr)
    stdout.close
    stderr.close

    expect(stdout.string).to match(%r{/remote_ruby})
  end

  it 'reads the input from stdin' do
    input = 'puts gets'
    stdin = StringIO.new("Hello, world!\n")
    stdout = StringIO.new
    stderr = StringIO.new
    adapter.open(input, stdin, stdout, stderr)
    stdout.close
    stderr.close
    expect(stdout.string).to eq("Hello, world!\n")
  end

  it 'calls external command' do
    stdout = StringIO.new
    stderr = StringIO.new
    adapter.open('puts Process.pid', StringIO.new, stdout, stderr)
    stdout.close
    stderr.close
    expect(stdout.string.to_i).not_to eq(Process.pid)
  end

  context 'when process fails' do
    it 'raises error' do
      stdout = StringIO.new
      stderr = StringIO.new
      expect do
        adapter.open('exit(127)', StringIO.new, stdout, stderr)
      end.to raise_error(RuntimeError, Regexp.new('127'))
    end
  end
end
