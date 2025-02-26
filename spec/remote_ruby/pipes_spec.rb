# frozen_string_literal: true

describe RemoteRuby::Pipes do
  describe '.with_pipes' do
    it 'yields an object with four pipes' do
      pipes = nil
      described_class.with_pipes do |p|
        pipes = p
        p.in_w.write('test in')
        p.out_w.write('test out')
        p.err_w.write('test err')
        p.res_w.write('test res')

        expect(p.in_r.readpartial(1000)).to eq('test in')
        expect(p.out_r.readpartial(1000)).to eq('test out')
        expect(p.err_r.readpartial(1000)).to eq('test err')
        expect(p.res_r.readpartial(1000)).to eq('test res')
      end

      expect(pipes.in_w).to be_closed
      expect(pipes.out_r).to be_closed
      expect(pipes.err_r).to be_closed
      expect(pipes.res_r).to be_closed
    end
  end
end
