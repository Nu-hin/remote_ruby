describe ::RemoteRuby::StdinProcessAdapter do
  class TestStdinAdapter < described_class; end

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
