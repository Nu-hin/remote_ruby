# frozen_string_literal: true

# rubocop:disable RSpec/ContextWording
shared_context 'common examples' do
  it 'writes to stdout' do
    expect do
      ec.execute do
        puts 'Hello, World!'
      end
    end.to output("Hello, World!\n").to_stdout
  end

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

  it 'writes to stderr' do
    expect do
      ec.execute do
        warn 'You have been warned!'
      end
    end.to output("You have been warned!\n").to_stderr
  end

  it 'reads from stdin' do
    data = 'a' * 600
    with_stdin_redirect(data) do
      expect do
        ec.execute do
          puts gets
        end
      end.to output("#{data}\n").to_stdout
    end
  end

  it 'reads binary data from stdin' do
    fname = File.join(__dir__, '../support/test_files/noise.png')

    res = with_stdin_redirect(File.binread(fname)) do
      ec.execute do
        $stdin.read
      end
    end

    expect(res).to eq(File.read(fname))
  end
end
# rubocop:enable RSpec/ContextWording
