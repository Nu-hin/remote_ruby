# frozen_string_literal: true

RSpec.describe RemoteRuby::TextModeAdapter do
  subject(:adapter) do
    described_class.new(
      base_adapter,
      stdout_prefix: stdout_prefix,
      stderr_prefix: stderr_prefix,
      cache_prefix: cache_prefix,
      cache_used: cache_used,
      stdout_mode: stdout_mode,
      stderr_mode: stderr_mode,
      cache_mode: cache_mode,
      disable_stdout_prefixing: disable_stdout_prefixing,
      disable_stderr_prefixing: disable_stderr_prefixing
    )
  end

  let(:base_adapter) { TestAdapter.new(out: output, err: error, result: result) }
  let(:stdout_prefix) { 'STDOUT: ' }
  let(:stderr_prefix) { 'STDERR: ' }
  let(:cache_prefix) { '[C] ' }
  let(:cache_used) { false }
  let(:stdout_mode) { { color: :green, mode: :italic } }
  let(:stderr_mode) { { color: :red, mode: :italic } }
  let(:cache_mode) { { color: :blue, mode: :bold } }
  let(:disable_stdout_prefixing) { false }
  let(:disable_stderr_prefixing) { false }
  let(:output) { 'Sample output' }
  let(:error) { 'Sample warning' }
  let(:result) { '' }

  describe '#open' do
    it 'prefixes stdout and stderr' do
      adapter.open('') do |_stdin, stdout, stderr, _result|
        expect(stdout.read).to eq("#{stdout_prefix.green.italic}#{output}")
        expect(stderr.read).to eq("#{stderr_prefix.red.italic}#{error}")
      end
    end
  end
end
