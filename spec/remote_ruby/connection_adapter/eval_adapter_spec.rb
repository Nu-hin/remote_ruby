describe ::RemoteRuby::EvalAdapter do
  shared_context 'Process and IO behaviour' do
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
  end

  context 'synchronous' do
    subject(:adapter) { described_class.new }
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
    subject(:adapter) { described_class.new(async: true) }
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
