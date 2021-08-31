# frozen_string_literal: true

RSpec.describe ::RemoteRuby::CodeExtractor do
  it 'works' do
    res = described_class.extract_block_ast do |_arg|
      puts 'Hello, World'
      break
    end

    code = Unparser.unparse(res)

    expect(code).to eq <<~RUBY
      puts("Hello, World")
      break
    RUBY
  end
end
