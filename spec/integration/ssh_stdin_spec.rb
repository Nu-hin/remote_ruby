# frozen_string_literal: true

describe 'Connecting to remote host with SSH STDIN adapter',
         type: :integration do
  let(:context) do
    RemoteRuby::ExecutionContext.new(
      adapter: RemoteRuby::SSHAdapter,
      host: ssh_host,
      user: ssh_user,
      working_dir: ssh_workdir
    )
  end

  context 'with do-blocks' do
    it 'succeeds and prints' do
      s = 'Something'

      expect do
        context.execute do
          puts s
        end
      end.to output(Regexp.new(s)).to_stdout
    end
  end

  context 'with {}-blocks' do
    it 'succeeds and prints' do
      s = 'Something'

      expect do
        context.execute { puts s }
      end.to output(Regexp.new(s)).to_stdout
    end
  end
end
