# frozen_string_literal: true

describe RemoteRuby::RemoteContext do
  let(:filename) { 'test_file.rb' }
  let(:rc) { described_class.new(filename) }

  describe '#initialize' do
    it 'initializes with a filename' do
      expect(rc.file_name).to eq(filename)
    end

    it 'initializes with no error' do
      expect(rc.has_error).to be false
    end

    it 'initializes with empty locals' do
      expect(rc.locals).to be_empty
    end
  end

  describe '#error?' do
    it 'returns false when there is no error' do
      expect(rc.error?).to be false
    end

    it 'returns true when there is an error' do
      rc.handle_error(StandardError.new('test error'))
      expect(rc.error?).to be true
    end
  end

  describe '#handle_error' do
    let(:error) { StandardError.new('test error') }

    before { rc.handle_error(error) }

    it 'sets the error class' do
      expect(rc.error_class).to eq('StandardError')
    end

    it 'sets the error message' do
      expect(rc.error_message).to eq('test error')
    end

    it 'sets the error backtrace' do
      expect(rc.error_backtrace).to eq(error.backtrace)
    end

    it 'sets has_error to true' do
      expect(rc.has_error).to be true
    end
  end

  describe '#execute' do
    context 'when block executes successfully' do
      it 'sets the result' do
        rc.execute { 42 }
        expect(rc.result).to eq(42)
      end

      it 'captures local variables' do
        x = rc.unmarshal(:x, Base64.strict_encode64(Marshal.dump(42)))
        y = rc.unmarshal(:y, Base64.strict_encode64(Marshal.dump(43)))

        rc.execute do
          x = 45
          y = 46
        end
        expect(rc.locals).to include(:x, :y)
        expect(rc.locals[:x]).to eq(45)
        expect(rc.locals[:y]).to eq(46)
      end
    end

    context 'when block raises an error' do
      it 'handles the error' do
        rc.execute { raise StandardError, 'test error' }
        expect(rc.error?).to be true
        expect(rc.error_message).to eq('test error')
      end
    end
  end

  describe '#dump' do
    it 'serializes the context' do
      expect(rc.dump).to be_a(String)
    end
  end

  describe '#unmarshal' do
    let(:data) { Base64.strict_encode64(Marshal.dump(42)) }

    it 'unmarshals the data' do
      rc.unmarshal(:test_var, data)
      expect(rc.locals[:test_var]).to eq(42)
    end

    it 'warns on invalid data' do
      expect do
        rc.unmarshal(:test_var,
                     'invalid data')
      end.to output(/Warning: could not resolve type for 'test_var' variable/).to_stderr
    end
  end
end
