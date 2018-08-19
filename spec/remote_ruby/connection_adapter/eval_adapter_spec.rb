describe ::RemoteRuby::EvalAdapter do
  shared_context 'Process and IO behaviour' do
    let(:working_dir) do
      File.realpath(Dir.mktmpdir)
    end

    after(:each) do
      FileUtils.rm_rf(working_dir)
    end

    it 'is launched in the same process' do
      new_pid = nil

      adapter.open('puts Process.pid') do |stdout, _stderr|
        new_pid = stdout.read.to_i
      end

      expect(new_pid).not_to be_nil
      expect(new_pid).not_to be_zero
      expect(new_pid).to eq(Process.pid)
    end

    it 'restores $stdout and $stderr variables' do
      new_pid = nil

      adapter.open('puts Process.pid') do |stdout, stderr|
        expect(stdout).not_to eq(STDOUT)
        expect(stderr).not_to eq(STDERR)
        new_pid = stdout.read.to_i
      end

      expect($stdout).to eq(STDOUT)
      expect($stderr).to eq(STDERR)
    end

    it 'changes to the working dir' do
      pwd = nil
      old_dir = Dir.pwd

      adapter.open('puts Dir.pwd') do |stdout, _stderr|
        pwd = stdout.read
        pwd.strip!
      end

      expect(pwd).to eq(working_dir)
      expect(Dir.pwd).to eq(old_dir)
    end
  end

  context 'synchronous' do
    subject(:adapter) { described_class.new(working_dir: working_dir) }
    include_context 'Process and IO behaviour'

    it 'is launched in the same thread' do
      new_thread_id = nil

      adapter.open('puts Thread.current.object_id') do |stdout, _stderr|
        new_thread_id = stdout.read.to_i
      end

      expect(new_thread_id).not_to be_nil
      expect(new_thread_id).not_to be_zero
      expect(new_thread_id).to eq(Thread.current.object_id)
    end
  end

  context 'asynchronous' do
    subject(:adapter) do
      described_class.new(async: true, working_dir: working_dir)
    end

    include_context 'Process and IO behaviour'

    it 'is launched in a different thread' do
      new_thread_id = nil

      adapter.open('puts Thread.current.object_id') do |stdout, _stderr|
        new_thread_id = stdout.read.to_i
      end

      expect(new_thread_id).not_to be_nil
      expect(new_thread_id).not_to be_zero
      expect(new_thread_id).not_to eq(Thread.current.object_id)
    end
  end
end
