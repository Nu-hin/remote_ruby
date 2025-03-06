# frozen_string_literal: true

shared_context 'shared examples' do
  subject(:ec) { RemoteRuby::ExecutionContext.new(**params) }

  let(:params) do
    adapter_specific_params.merge(additional_params)
  end

  let(:additional_params) { {} }

  before do
    RemoteRuby.configure do |c|
      c.cache_dir = Dir.mktmpdir
      c.code_dir = Dir.mktmpdir
    end
  end

  after do
    FileUtils.remove_entry(RemoteRuby.cache_dir)
    FileUtils.remove_entry(RemoteRuby.code_dir)
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

  context 'with stdin redirection' do
    context 'when redirecting from StringIO' do
      let(:input) { StringIO.new("John Doe\n") }
      let(:additional_params) do
        {
          in_stream: input
        }
      end

      it 'reads from the stream' do
        res = ec.execute do
          gets
        end

        expect(res).to eq("John Doe\n")
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

    context 'when caching mode is enabled' do
      let(:additional_params) { { save_cache: true, in_stream: StringIO.new("John doe\n") } }
      let(:cec) { RemoteRuby::ExecutionContext.new(**params, use_cache: true) }

      it 'replays stdout and stderr' do
        expect do
          ec.execute do
            puts 'Hello, World!'
            warn 'Something went wrong!'
          end
        end.to output("Hello, World!\n").to_stdout.and output("Something went wrong!\n").to_stderr

        expect do
          cec.execute do
            puts 'Hello, World!'
            warn 'Something went wrong!'
          end
        end.to output("Hello, World!\n")
          .to_stdout
          .and output("Something went wrong!\n").to_stderr
      end

      it 'ignores stdin on replay' do
        expect do
          ec.execute do
            puts gets
          end
        end.to output("John doe\n").to_stdout

        expect do
          cec.execute do
            puts gets
          end
        end.to output("John doe\n").to_stdout
      end
    end

    context 'with do-blocks' do
      let(:additional_params) { { in_stream: StringIO.new("John doe\n") } }

      it 'reads string from stdin' do
        expect do
          ec.execute do
            puts gets
          end
        end.to output("John doe\n").to_stdout
      end

      it 'receives integer result' do
        result = ec.execute do
          17 + 5
        end

        expect(result).to eq(22)
      end

      it 'passers integer locals' do
        x = 17
        y = 5
        result = ec.execute do
          x + y
        end

        expect(result).to eq(22)
      end

      it 'passes binary data' do
        fname = File.join(__dir__, '../support/test_files/noise.png')

        var = nil
        res = ec.execute(fname: fname, data: File.read(fname), var: var) do
          var = data
          var
        end

        expect(res).to eq(File.read(fname))
        expect(res).to eq(var)
      end

      it 'receives string result' do
        result = ec.execute do
          'a' * 3
        end

        expect(result).to eq('aaa')
      end

      it 'prints to stdout' do
        s = 'Something'

        expect do
          ec.execute do
            puts s
          end
        end.to output("#{s}\n").to_stdout
      end

      it 'prints to stderr' do
        s = 'Something'

        expect do
          ec.execute do
            warn s
          end
        end.to output("#{s}\n").to_stderr
      end

      it 'receives complex local context' do
        a = 3
        b = 'Hello'
        c = 5.0
        d = Time.new(2025, 1, 1)
        e = nil
        f = [1, 2, 3]
        g = { a: 1, b: 2 }

        result = ec.execute do
          {
            a: a * 2,
            b: "#{b} World",
            c: c * 2,
            d: Time.new(d.year + 1, d.month, d.day),
            e: e.nil?,
            f: f.map { |x| x * 2 },
            g: g.transform_values { |v| v * 2 }
          }
        end

        expect(result).to eq(
          a: 6,
          b: 'Hello World',
          c: 10.0,
          d: Time.new(2026, 1, 1),
          e: true,
          f: [2, 4, 6],
          g: { a: 2, b: 4 }
        )
      end

      it 'modifies local variables' do
        a = 3
        b = 'Hello'
        c = 5.0
        d = Time.new(2025, 1, 1)
        e = nil
        f = [1, 2, 3]
        g = { a: 1, b: 2 }

        ec.execute do
          a *= 2
          b = "#{b} World"
          c *= 2
          d = Time.new(d.year + 1, d.month, d.day)
          e = e.nil?
          f = f.map { |x| x * 2 }
          g = g.transform_values { |v| v * 2 }
        end

        expect(a).to eq(6)
        expect(b).to eq('Hello World')
        expect(c).to eq(10.0)
        expect(d).to eq(Time.new(2026, 1, 1))
        expect(e).to be(true)
        expect(f).to eq([2, 4, 6])
        expect(g).to eq(a: 2, b: 4)
      end
    end

    context 'with {}-blocks' do
      it 'prints to stdout' do
        s = 'Something'

        expect do
          ec.execute { puts s }
        end.to output(Regexp.new(s)).to_stdout
      end
    end
  end
end
