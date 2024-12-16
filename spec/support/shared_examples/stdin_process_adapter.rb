# frozen_string_literal: true

shared_context 'STDIN adapter' do
  describe '#open' do
    let(:code) { '1 + 1' }
    let(:output_content) { 'output' }
    let(:error_content) { 'error' }
    let(:fake_stdin) { StringIO.new }
    let(:wait_thr) { double(:wait_thr, value: value) }
    let(:value) { double(:value, success?: success?, to_s: exit_code.to_s) }
    let(:success?) { true }
    let(:exit_code) { 0 }
    let(:bundler) { false }

    before(:example) do
      allow(adapter).to receive(:popen3).and_yield(
        fake_stdin,
        StringIO.new(output_content),
        StringIO.new(error_content),
        wait_thr
      )
    end

    # rubocop:disable Lint/EmptyBlock
    it 'writes code to stdin' do
      adapter.open(code) {}
      expect(fake_stdin.string).to eq(code)
    end

    it 'yields streams' do
      adapter.open(code) do |stdout, stderr|
        expect(stdout.read).to eq(output_content)
        expect(stderr.read).to eq(error_content)
      end
    end

    it 'calls external command' do
      allow(adapter).to receive(:command).and_return('echo')
      expect(adapter).to receive(:popen3).with('echo')
      adapter.open(code) {}
    end

    context 'with bundler' do
      let(:bundler) { true }

      it 'includes bundle exec to the command' do
        expect(adapter).to receive(:popen3).with(match(/bundle exec/))
        adapter.open(code) {}
      end
    end

    context 'when process fails' do
      let(:success?) { false }
      let(:exit_code) { 127 }

      it 'raises error' do
        expect do
          adapter.open(code) {}
        end.to raise_error(RuntimeError, Regexp.new(value.to_s))
      end
    end
    # rubocop:enable Lint/EmptyBlock
  end
end
