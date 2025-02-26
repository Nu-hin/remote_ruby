module RemoteRuby
  class RemoteError < StandardError
    attr_reader :code_source, :remote_error_class, :remote_error_message, :remote_error_backtrace

    def initialize(code_source, remote_error_class, remote_error_message, remote_error_backtrace)
      super('Unhandled remote error')
      @code_source = code_source
      @remote_error_class = remote_error_class
      @remote_error_message = remote_error_message
      @remote_error_backtrace = remote_error_backtrace
    end

    def format_source(line_no, context_lines: 3)
      numbered = code_source.lines.map.with_index(1) do |line, index|
        if index == line_no
          "#{index}: >> #{line}"
        else
          "#{index}:    #{line}"
        end
      end

      numbered[(line_no - context_lines - 1)..(line_no + context_lines - 1)]
    end

    def message
      rex = %r{(^.*(^|/)remote_ruby\..*):(\d+):in (.*)$}
      res = StringIO.new
      res.puts super
      res.puts "Remote error: #{remote_error_class}"
      res.puts "Message: #{remote_error_message}"
      res.puts 'Backtrace:'

      remote_error_backtrace.each do |line|
        res.puts
        res.puts line

        next unless (m = rex.match(line))

        res.puts
        format_source(m[3].to_i).each do |l|
          res.puts l
        end
      end

      res.string
    end
  end
end
