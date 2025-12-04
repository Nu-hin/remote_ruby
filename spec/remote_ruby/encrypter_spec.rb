# frozen_string_literal: true

describe RemoteRuby::Encrypter do
  subject(:encrypter) do
    described_class.new(
      plaintext_code
    )
  end

  let(:plaintext_code) { 'raise "Hello world"' }

  describe '#compiled_code' do
    subject(:compiled_code) { encrypter.compiled_code }

    it 'has key' do
      expect(compiled_code).to be_a(String)
      expect(encrypter.key_base64).not_to be_nil
    end

    it 'produces ruby code' do
      expect(compiled_code).to be_a(String)
      expect(compiled_code).to include("cipher = OpenSSL::Cipher.new('aes-256-cbc')")
    end
  end
end
