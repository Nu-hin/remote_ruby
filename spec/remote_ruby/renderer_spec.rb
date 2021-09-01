# frozen_string_literal: true

RSpec.describe ::RemoteRuby::Renderer do
  it 'works' do
    renderer = described_class.new
    script = <<~RUBY
      a = a + 1
      b = b + " World"
      "\#{a} \#{b}"
    RUBY

    ast = Parser::CurrentRuby.parse(script)

    rb = renderer.render(ast, { a: 1, b: 'Hello' })

    binder = Object.new
    expect(binder.instance_eval(rb)).to eq('2 Hello World')
  end
end
