# frozen_string_literal: true

describe 'Connecting to remote host with SSH adapter',
         type: :integration do
  let(:save_cache) { false }
  let(:in_stream) { StringIO.new("John doe\n") }
  let(:ec) do
    RemoteRuby::ExecutionContext.new(
      host: ssh_host,
      in_stream: in_stream,
      working_dir: ssh_workdir,
      use_cache: false,
      save_cache: save_cache,
      use_ssh_config_file: ssh_use_config_file,
      **ssh_config
    )
  end

  before do
    RemoteRuby.configure do |c|
      c.cache_dir = Dir.mktmpdir
    end
  end

  after do
    RemoteRuby.clear_cache
  end

  context 'when caching mode is enabled' do
    let(:save_cache) { true }
    let(:cec) do
      RemoteRuby::ExecutionContext.new(
        host: ssh_host,
        working_dir: ssh_workdir,
        use_cache: true,
        save_cache: false,
        use_ssh_config_file: ssh_use_config_file,
        **ssh_config
      )
    end

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
