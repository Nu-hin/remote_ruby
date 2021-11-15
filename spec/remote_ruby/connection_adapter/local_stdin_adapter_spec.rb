# frozen_string_literal: true

require 'support/shared_examples/stdin_process_adapter'

describe ::RemoteRuby::LocalStdinAdapter do
  include_context 'STDIN adapter'
  subject(:adapter) { described_class.new(working_dir: working_dir) }

  let(:working_dir) do
    File.realpath(Dir.mktmpdir)
  end

  after(:each) do
    FileUtils.rm_rf(working_dir)
  end

  describe '#connection_name' do
    it 'equals to working_dir' do
      expect(adapter.connection_name).to eq(working_dir)
    end
  end

  describe '#open' do
    it 'changes to the working dir' do
      pwd = nil

      adapter.open('puts Dir.pwd') do |stdout, _stderr|
        pwd = stdout.read
        pwd.strip!
      end

      expect(pwd).to eq(working_dir)
    end

    it 'is launched in a separate process' do
      new_pid = nil

      adapter.open('puts Process.pid') do |stdout, _stderr|
        new_pid = stdout.read.to_i
      end

      expect(new_pid).not_to be_nil
      expect(new_pid).not_to be_zero
      expect(new_pid).not_to eq(Process.pid)
    end
  end
end
