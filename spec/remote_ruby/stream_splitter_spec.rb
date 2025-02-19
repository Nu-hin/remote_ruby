# frozen_string_literal: true

describe StreamSplitter do
  subject(:reader) { described_class.new(stream, terminator) }

  let(:terminator) { "%%%MAGIC\n" }
  let(:data) { "before#{terminator}after" }
  let(:stream) { StringIO.new(data) }
  let(:remainder) { stream.read }

  describe '#slice_safe!' do
    let(:terminator) { '%TERM%' }

    it 'slices the buffer' do
      # [buffer, max_len, eof, expected_prefix, expected_buffer]
      [
        ['', 10, false, '', ''],
        ['', nil, false, '', ''],
        ['%TERM%', 10, false, '', '%TERM%'],
        ['%TERM%', nil, false, '', '%TERM%'],
        ['a%TERM', 10, false, 'a', '%TERM'],
        ['abc%TE', 10, false, 'abc', '%TE'],
        ['abc%TE', 10, true, 'abc%TE', ''],
        ['%TERM%', 10, true, '', '%TERM%']
      ].each do |buffer, max_len, eof, expected_prefix, expected_buffer|
        b = buffer.nil? ? nil : String.new(buffer)
        expect(reader.slice_safe!(b, max_len, terminator, eof)).to eq(expected_prefix)
        expect(b).to eq(expected_buffer)
      end
    end
  end

  describe '#readpartial' do
    context 'when stream contains no terminator' do
      let(:data) { 'before' }

      it 'reads the whole stream' do
        expect(reader.readpartial(1000)).to eq('before')
        expect { reader.readpartial(1000) }.to raise_error(EOFError)
        expect(stream).to be_eof
      end

      it 'reads the whole stream in chunks' do
        expect(reader.readpartial(2)).to eq('be')
        expect(reader.readpartial(2)).to eq('fo')
        expect(reader.readpartial(3)).to eq('re')
        expect { reader.readpartial(2) }.to raise_error(EOFError)
        expect(stream).to be_eof
      end
    end

    context 'when stream contains no data and is eof' do
      let(:data) { '' }

      it 'raises EOFError' do
        expect { reader.readpartial(1000) }.to raise_error(EOFError)
        expect(stream).to be_eof
      end
    end

    context 'when stream contains no data and is open' do
      let(:pipe) { IO.pipe }
      let(:stream) { pipe.first }
      let(:writer) { pipe.last }

      it 'blocks until data is available' do
        res = nil
        t = Thread.new do
          res = reader.readpartial(1)
        end

        sleep 0.1
        expect(res).to be_nil
        writer.write('a')
        t.join
        expect(res).to eq('a')
      end

      it 'blocks until stream is closed' do
        res = nil
        t = Thread.new do
          reader.readpartial(1)
        rescue EOFError
          res = 'EOF'
        end

        sleep 0.1
        expect(res).to be_nil
        writer.close
        t.join
        expect(res).to eq('EOF')
      end
    end

    context 'when stream consists of terminator' do
      let(:data) { terminator }

      it 'raises eof immediately' do
        expect { reader.readpartial(10) }.to raise_error(EOFError)
        expect(reader).to be_eof
      end
    end

    context 'when stream starts with terminator' do
      let(:data) { "#{terminator}after" }

      it 'raises eof immediately' do
        expect { reader.readpartial(10) }.to raise_error(EOFError)
        expect(reader).to be_eof
        expect(stream).not_to be_eof
        expect(remainder).to eq('after')
        expect(stream).to be_eof
      end
    end

    context 'when stream ends with terminator' do
      let(:data) { "before#{terminator}" }

      it 'reads the whole stream' do
        expect(reader.readpartial(1000)).to eq('before')
        expect { reader.readpartial(1000) }.to raise_error(EOFError)
        expect(reader).to be_eof
        expect(stream).to be_eof
      end

      it 'reads the whole stream in chunks' do
        expect(reader.readpartial(2)).to eq('be')
        expect(reader.readpartial(2)).to eq('fo')
        expect(reader.readpartial(3)).to eq('re')
        expect { reader.readpartial(2) }.to raise_error(EOFError)
        expect(stream).to be_eof
      end
    end

    context 'when stream contains terminator in the middle' do
      it 'reads the whole stream' do
        expect(reader.readpartial(1000)).to eq('before')
        expect { reader.readpartial(1000) }.to raise_error(EOFError)
        expect(reader).to be_eof
        expect(stream).not_to be_eof
        expect(remainder).to eq('after')
        expect(stream).to be_eof
      end

      it 'reads the whole stream in chunks' do
        expect(reader.readpartial(2)).to eq('be')
        expect(reader.readpartial(2)).to eq('fo')
        expect(reader.readpartial(3)).to eq('re')
        expect { reader.readpartial(2) }.to raise_error(EOFError)
        expect(reader).to be_eof
        expect(stream).not_to be_eof
        expect(remainder).to eq('after')
        expect(stream).to be_eof
      end
    end

    context 'when stream starts with partial terminator' do
      let(:data) { '%%%MAGICafter' }

      it 'reads the whole stream' do
        res = String.new

        loop do
          res << reader.readpartial(100)
        rescue EOFError
          break
        end

        expect(res).to eq('%%%MAGICafter')

        expect { reader.readpartial(1000) }.to raise_error(EOFError)
        expect(reader).to be_eof
        expect(stream).to be_eof
      end
    end

    context 'when stream ends with partial terminator' do
      let(:terminator) { "%%%MAGIC\n" }
      let(:data) { 'before%%%MAGIC' }

      it 'reads the whole stream' do
        res = String.new

        loop do
          res << reader.readpartial(100)
        rescue EOFError
          break
        end

        expect(res).to eq('before%%%MAGIC')

        expect { reader.readpartial(1000) }.to raise_error(EOFError)
        expect(reader).to be_eof
        expect(stream).to be_eof
      end
    end

    context 'when stream contains partial terminator' do
      let(:terminator) { "%%%MAGIC\n" }
      let(:data) { 'before%%%MAGICafter' }

      it 'reads the whole stream' do
        res = String.new

        loop do
          res << reader.readpartial(100)
        rescue EOFError
          break
        end

        expect(res).to eq('before%%%MAGICafter')

        expect { reader.readpartial(1000) }.to raise_error(EOFError)
        expect(reader).to be_eof
        expect(stream).to be_eof
      end
    end

    context 'when stream contains binary data' do
      let(:bin_data_fpart) do
        [137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72,
         68, 82, 0, 0, 1, 0, 0, 0, 1, 0, 16, 0, 0, 0, 0, 41, 137,
         43, 249, 0, 0, 0, 2, 98, 75, 71, 68, 255, 255, 20, 171,
         49, 205, 0, 0, 0, 7, 116, 73, 77, 69, 7, 233, 2, 15, 19]
      end

      let(:bin_data_spart) do
        [43, 55, 15, 145, 230, 147, 0, 0, 128, 0, 73, 68, 65, 84,
         120, 218, 4, 193, 3, 96, 84, 13, 0, 0, 224, 187, 123, 103,
         219, 156, 237, 26, 90, 110, 153, 203, 182, 93, 127, 182]
      end

      let(:data) { (bin_data_fpart + terminator.bytes + bin_data_spart).pack('C*') }

      it 'reads the whole stream' do
        res = String.new

        loop do
          res << reader.readpartial(100)
        rescue EOFError
          break
        end

        expect(res.bytes).to eq(bin_data_fpart)
        expect { reader.readpartial(1000) }.to raise_error(EOFError)
        expect(reader).to be_eof

        expect(remainder.bytes).to eq(bin_data_spart)
        expect(stream).to be_eof
      end
    end
  end
end
