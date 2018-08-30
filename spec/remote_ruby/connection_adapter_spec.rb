describe ::RemoteRuby::ConnectionAdapter do
  let(:concrete_adapter_klass) { Class.new(described_class) }
  subject(:adapter) { concrete_adapter_klass.new }

  describe '#open' do
    it 'raises NotImplementedError' do
      expect do
        adapter.open('1+1')
      end.to raise_error NotImplementedError
    end
  end
end
