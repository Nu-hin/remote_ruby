# frozen_string_literal: true

describe ::RemoteRuby::ConnectionAdapter do
  class TestAdapter < described_class; end

  subject(:adapter) { TestAdapter.new }

  describe '#open' do
    it 'raises NotImplementedError' do
      expect do
        adapter.open('1+1')
      end.to raise_error NotImplementedError
    end
  end

  describe '#connection_name' do
    it 'equals to class name by default' do
      expect(adapter.connection_name).to eq('TestAdapter')
    end
  end
end
