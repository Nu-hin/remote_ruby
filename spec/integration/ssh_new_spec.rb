# frozen_string_literal: true

describe 'Running over SSH', type: :integration do
  subject(:ec) do
    RemoteRuby::ExecutionContext.new(**params)
  end

  include_context 'shared examples'

  let(:params) do
    {
      host: ssh_host,
      working_dir: ssh_workdir,
      use_ssh_config_file: ssh_use_config_file,
      **ssh_config
    }.merge(additional_params)
  end

  let(:additional_params) { {} }

  let(:working_dir) { Dir.mktmpdir }

  after do
    FileUtils.remove_entry(working_dir)
  end
end
