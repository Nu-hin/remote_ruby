# frozen_string_literal: true

require 'support/shared_examples/stdin_process_adapter'

describe RemoteRuby::SSHStdinAdapter do
  include_context 'STDIN adapter'

  subject(:adapter) { described_class.new(**params) }

  let(:working_dir) { '/var/ruby_project' }
  let(:server) { 'ssh_host' }
  let(:username) { 'dev' }
  let(:key_file) { '/home/dev/.ssh/special_key' }

  let(:params) do
    {
      working_dir: working_dir,
      server: server,
      user: username,
      key_file: key_file,
      bundler: bundler
    }
  end
end
