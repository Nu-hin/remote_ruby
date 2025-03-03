# frozen_string_literal: true

RSpec.describe RemoteRuby::StreamPrefixer do
  def prefix(*input)
    sp = described_class.new(StringIO.new, 'PREFIX: ')
    input.each { |i| sp.write(i) }
    sp.stream.close
    sp.stream.string
  end

  describe '#write' do
    it 'prefixes correctly' do
      expect(prefix('')).to eq('')
      expect(prefix("\n")).to eq("PREFIX: \n")
      expect(prefix("\n\n")).to eq("PREFIX: \nPREFIX: \n")
      expect(prefix('line')).to eq('PREFIX: line')
      expect(prefix('line1', "\nline2")).to eq("PREFIX: line1\nPREFIX: line2")
      expect(prefix("line\n")).to eq("PREFIX: line\n")
      expect(prefix("line1\nli", "ne2\nlin", 'e3')).to eq("PREFIX: line1\nPREFIX: line2\nPREFIX: line3")
    end
  end
end
