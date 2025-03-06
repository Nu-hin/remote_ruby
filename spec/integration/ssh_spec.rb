# frozen_string_literal: true

describe 'Running over SSH', type: %i[integration ssh] do
  include_context 'shared examples'

  let(:adapter_specific_params) do
    {
      host: ssh_host,
      working_dir: ssh_workdir,
      use_ssh_config_file: ssh_use_config_file,
      **ssh_config
    }
  end
end
