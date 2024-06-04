# frozen_string_literal: true

describe RemoteRuby::StdinProcessAdapter do
  # rubocop:disable Lint/ConstantDefinitionInBlock
  class TestStdinAdapter < described_class; end
  # rubocop:enable Lint/ConstantDefinitionInBlock

  subject(:adapter) { TestStdinAdapter.new }

  describe '#open' do
    it 'raises NotImplementedError' do
      expect(adapter).to receive(:command).and_call_original

      expect do
        adapter.open('1+1')
      end.to raise_error(NotImplementedError)
    end
  end
end
