describe ::RemoteRuby::LocalStdinAdapter do
  subject(:adapter) { described_class.new(working_dir: working_dir) }

  let(:working_dir) do
    Dir.mktmpdir
  end

  let(:cache_dir) do
    Dir.mktmpdir
  end

  after(:each) do
    FileUtils.rm_rf(working_dir)
    FileUtils.rm_rf(cache_dir)
  end

  it 'changes to the working dir' do
    pwd = nil

    adapter.open do |stdin, stdout, stderr|
      stdin.puts("puts Dir.pwd")
      stdin.close
      pwd = stdout.read
      pwd.strip!
    end

    expect(pwd).to eq(working_dir)
  end
end
