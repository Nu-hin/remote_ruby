# frozen_string_literal: true

describe RemoteRuby::EvalAdapter do
  subject(:adapter) do
    described_class.new(working_dir: working_dir)
  end

  let(:working_dir) do
    File.realpath(Dir.mktmpdir)
  end

  after do
    FileUtils.rm_rf(working_dir)
  end

  it 'is launched in the same process' do
    new_pid = nil

    adapter.open('puts; puts Process.pid') do |_stdin, stdout, _stderr, _result|
      new_pid = stdout.read.to_i
    end

    expect(new_pid).not_to be_nil
    expect(new_pid).not_to be_zero
    expect(new_pid).to eq(Process.pid)
  end

  # rubocop:disable Style/GlobalStdStream
  it 'restores $stdout and $stderr variables' do
    adapter.open('puts; puts Process.pid') do |_stdin, stdout, stderr, _result|
      expect(stdout).not_to eq(STDOUT)
      expect(stderr).not_to eq(STDERR)
    end

    expect($stdout).to eq(STDOUT)
    expect($stderr).to eq(STDERR)
  end
  # rubocop:enable Style/GlobalStdStream

  it 'changes to the working dir' do
    pwd = nil
    old_dir = Dir.pwd

    adapter.open('puts; puts Dir.pwd') do |_stdin, stdout, _stderr, _result|
      pwd = stdout.read
      pwd.strip!
    end

    expect(pwd).to eq(working_dir)
    expect(Dir.pwd).to eq(old_dir)
  end

  it 'is launched in a different thread' do
    new_thread_id = nil

    adapter.open('puts; puts Thread.current.object_id') do |_stdin, stdout, _stderr, _result|
      new_thread_id = stdout.read.to_i
    end

    expect(new_thread_id).not_to be_nil
    expect(new_thread_id).not_to be_zero
    expect(new_thread_id).not_to eq(Thread.current.object_id)
  end

  it 'returns marshalled result' do
    result = nil
    out = nil

    adapter.open('puts 2; print "%%%MARSHAL\nTEST"') do |_stdin, stdout, _stderr, res|
      out = stdout.read
      result = res.read
    end

    expect(out).to eq("2\n")
    expect(result).to eq('TEST')
  end
end
