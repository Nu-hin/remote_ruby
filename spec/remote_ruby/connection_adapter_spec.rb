# frozen_string_literal: true

describe RemoteRuby::ConnectionAdapter do
  # rubocop:disable Lint/ConstantDefinitionInBlock
  class TestAdapter < described_class; end
  # rubocop:enable Lint/ConstantDefinitionInBlock

  subject(:adapter) { TestAdapter.new }

  describe '#open' do
    it 'raises NotImplementedError' do
      expect do
        adapter.open('1+1')
      end.to raise_error NotImplementedError
    end
  end
end
