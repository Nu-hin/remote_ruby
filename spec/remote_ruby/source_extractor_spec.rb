describe RemoteRuby::SourceExtractor do
  subject { described_class.new }


  context 'with do-block' do
    context 'well-formatted' do
      context 'without arguments' do
        it 'returns correct value' do
          res = subject.extract do
            code_source
          end

          expect(res.strip).to eq('code_source')
        end
      end

      context 'with arguments' do
        it 'returns correct value' do
          res = subject.extract do |context, a, b|
            code_source
          end

          expect(res.strip).to eq('code_source')
        end
      end
    end
  end
end
