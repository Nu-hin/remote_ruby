describe RemoteRuby::Compiler do
  subject(:compiler) do
    described_class.new(
      client_code,
      client_locals: client_locals,
      flavours: flavours
    )
  end

  let(:client_code) { '3 + 3' }
  let(:client_locals) { {} }
  let(:flavours) { [] }

  shared_context 'normal behaviour' do
    subject(:compiled_code) { compiler.compiled_code }

    it 'includes client code' do
      expect(compiled_code).to include(client_code)
    end

    # rubocop:disable Security/Eval, Style/EvalWithLocation
    it 'produces correct code' do
      expect { eval("lambda { #{compiled_code} }") }.not_to raise_error
    end

    it 'outputs marshal values' do
      expect { eval(compiled_code) }.to output(/%%%MARSHAL/).to_stdout
    end
    # rubocop:enable Security/Eval, Style/EvalWithLocation
  end

  describe '#compiled_code' do
    include_context 'normal behaviour'

    context 'with locals' do
      let(:client_locals) { { a: 1, b: 'string', c: [1, 2] } }
      include_context 'normal behaviour'

      it 'includes locals serialization' do
        client_locals.each do |name, _|
          expect(compiled_code).to include("#{name} = begin")
        end
      end

      context 'when local cannot be dumped' do
        let(:client_locals) { { file: File.open('/dev/null', 'w') } }
        it 'prints out a warning' do
          expect { compiled_code }.to output(/file/).to_stderr
        end
      end
    end

    context 'with flavours' do
      let(:flavours) do
        (1..3).map do |i|
          double(
            :flavour_a,
            code_header: "\"code header from flavour #{i}\""
          )
        end
      end

      include_context 'normal behaviour'

      it 'includes flavour headers' do
        flavours.each do |f|
          expect(compiled_code).to include(f.code_header)
        end
      end
    end
  end

  describe '#code_hash' do
    it 'produces a hash' do
      expect(compiler.code_hash.size).to eq(64)
    end

    it 'changes when code changes' do
      different_source_hash = described_class.new('4+4').code_hash
      different_locals_hash =
        described_class.new(client_code, client_locals: { e: 34 }).code_hash

      flavour = double(:flavour, code_header: "require 'open3'")

      different_flavours_hash =
        described_class.new(
          client_code,
          client_locals: client_locals,
          flavours: [flavour]
        ).code_hash

      hashes = [
        compiler.code_hash,
        different_source_hash,
        different_locals_hash,
        different_flavours_hash
      ]

      expect(hashes.uniq.count).to eq hashes.count
    end
  end
end
