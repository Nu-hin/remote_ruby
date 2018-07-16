RSpec.shared_context 'integration config' do
  let(:config) do
    config_file_name = File.expand_path('config.yml', __dir__)
    return {} unless File.exist?(config_file_name)
    YAML.load(File.read(config_file_name))
  end

  let(:ssh_host) { config['ssh']['host'] }
  let(:ssh_user) { config['ssh']['user'] }
  let(:ssh_key_file) { config['ssh']['key_file'] }
  let(:ssh_workdir) { config['ssh']['workdir'] }
end

RSpec.configure do |config|
  config.include_context 'integration config', type: :integration
end
