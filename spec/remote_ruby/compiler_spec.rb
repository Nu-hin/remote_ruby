# frozen_string_literal: true

describe RemoteRuby::Compiler do
  subject(:compiler) do
    described_class.new(
      client_code,
      client_locals: client_locals,
      plugins: plugins
    )
  end

  let(:client_code) { '3 + 3' }
  let(:client_locals) { {} }
  let(:plugins) { [] }

  shared_context 'normal behaviour' do # rubocop:disable RSpec/ContextWording
    subject(:compiled_code) { compiler.compiled_code }

    it 'includes client code' do
      expect(compiled_code).to include(client_code)
    end

    # rubocop:disable Security/Eval, Style/EvalWithLocation, Style/DocumentDynamicEvalDefinition
    it 'produces correct code' do
      expect { eval("lambda { #{compiled_code} }") }.not_to raise_error
    end
    # rubocop:enable Security/Eval, Style/EvalWithLocation, Style/DocumentDynamicEvalDefinition
  end

  describe '#compiled_code' do
    include_context 'normal behaviour'

    context 'with locals' do
      let(:client_locals) { { a: 1, b: 'string', c: [1, 2] } }

      include_context 'normal behaviour'

      it 'includes locals serialization' do
        client_locals.each_key do |name|
          expect(compiled_code).to include("#{name} = begin")
        end
      end

      context 'when local cannot be dumped' do
        let(:client_locals) { { file: File.open(File::NULL, 'w') } }

        it 'prints out a warning' do
          expect { compiled_code }.to output(/file/).to_stderr
        end
      end
    end

    context 'with plugins' do
      let(:plugin) do
        (1..3).map do |i|
          instance_double(
            RemoteRuby::Plugin,
            code_header: "\"code header from plugin #{i}\""
          )
        end
      end

      include_context 'normal behaviour'

      it 'includes plugin headers' do
        plugins.each do |f|
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

      plugin = instance_double(RemoteRuby::Plugin, code_header: "require 'open3'")

      different_plugins_hash =
        described_class.new(
          client_code,
          client_locals: client_locals,
          plugins: [plugin]
        ).code_hash

      hashes = [
        compiler.code_hash,
        different_source_hash,
        different_locals_hash,
        different_plugins_hash
      ]

      expect(hashes.uniq.count).to eq hashes.count
    end
  end
end
