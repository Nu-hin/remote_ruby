describe 'Connecting to remote host with SSH STDIN adapter', type: :integration do
  let(:context) do
    ::RemoteRuby::ExecutionContext.new(
      adapter: ::RemoteRuby::SSHStdinAdapter,
      server: ssh_host,
      user: ssh_user,
      key_file: ssh_key_file,
      working_dir: ssh_workdir
    )
  end

  it 'succeeds and prints' do
    s = 'Something'

    expect do
      context.execute do
        puts s
      end
    end.to output(Regexp.new(s)).to_stdout
  end
end
