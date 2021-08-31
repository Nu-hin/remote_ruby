# frozen_string_literal: true

RSpec.describe ::RemoteRuby::Renderer do
  it 'works' do
    renderer = described_class.new
    script = <<~RUBY
      a = a + 1
      b = b + " World"
    RUBY

    ast = Parser::CurrentRuby.parse(script)

    rb = renderer.render(ast, { a: 1, b: 'Hello' })

    Object.new do
      binding.eval(rb)

      expect(a).to eq(2)
      expect(b).to eq('Hello World')
    end
  end
end
