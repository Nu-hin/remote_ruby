# frozen_string_literal: true

# rubocop:disable RSpec/ContextWording
shared_context 'common examples' do
  context 'with stdout redirection' do
    context 'when redirecting to StringIO' do
      let(:output) { StringIO.new }
      let(:additional_params) do
        {
          out_stream: output
        }
      end

      it 'writes to the stream' do
        ec.execute do
          puts 'Hello, World!'
        end

        expect(output.string).to eq("Hello, World!\n")
      end
    end

    context 'when redirecting to a file' do
      let(:tmp_file) { Tempfile.create('output') }
      let(:additional_params) do
        {
          out_stream: tmp_file
        }
      end

      after do
        File.unlink(tmp_file.path)
      end

      it 'writes to the file' do
        ec.execute do
          puts 'Hello, World!'
        end

        tmp_file.close

        expect(File.read(tmp_file.path)).to eq("Hello, World!\n")
      end
    end
  end

  context 'with stdin redirection' do
    context 'when redirecting from StringIO' do
      let(:input) { StringIO.new("John doe\n") }
      let(:additional_params) do
        {
          in_stream: input
        }
      end

      it 'reads from the stream' do
        res = ec.execute do
          gets
        end

        expect(res).to eq("John doe\n")
      end
    end

    context 'when redirecting from a file' do
      let(:filename) { File.join(__dir__, '../support/test_files/noise.png') }
      let(:file) { File.open(filename, 'rb') }

      let(:additional_params) do
        {
          in_stream: file
        }
      end

      it 'reads binary data from stdin' do
        res = ec.execute do
          $stdin.read
        end

        file.close

        expect(res).to eq(File.read(filename))
      end
    end
  end
end
# rubocop:enable RSpec/ContextWording
