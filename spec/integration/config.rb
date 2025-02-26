# frozen_string_literal: true

RSpec.shared_context 'integration config' do # rubocop:disable RSpec/ContextWording
  let(:config) do
    config_file_name = File.expand_path('config.yml', __dir__)
    return {} unless File.exist?(config_file_name)

    YAML.safe_load(File.read(config_file_name))
  end

  let(:ssh_host) { config['ssh']['host'] }
  let(:ssh_workdir) { config['ssh']['workdir'] }
  let(:ssh_use_config_file) { config['ssh'].fetch('use_config_file', true) }
  let(:ssh_config) { config['ssh'].fetch('config', {}).transform_keys(&:to_sym) }
end

RSpec.configure do |config|
  config.include_context 'integration config', type: :integration
end
