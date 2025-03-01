# frozen_string_literal: true

require 'stringio'
module RemoteRuby
  # Raised when an error occurs during remote execution
  # Wraps the original error and provides additional information
  # about the error and the source code that caused it.
  # Allows to display the source code around the line that caused the error.
  class RemoteError < StandardError
    attr_reader :code_source, :remote_context, :source_path, :stack_trace_regexp

    def initialize(code_source, remote_context, source_path)
      @code_source = code_source
      @remote_context = remote_context
      @source_path = source_path
      @stack_trace_regexp = /^#{Regexp.escape(remote_context.file_name)}:(?<line_number>\d+):in (?<method_name>.*)$/
      super(build_message)
    end

    private

    def format_source(line_no, context_lines: 3)
      code_source.lines.each.with_index(1).drop(line_no - context_lines - 1)
                 .take((2 * context_lines) + 1).map do |line, index|
        if index == line_no
          "#{index}: >> #{line}"
        else
          "#{index}:    #{line}"
        end
      end
    end

    def build_message
      res = StringIO.new
      res.puts "Remote error: #{remote_context.error_class}"
      res.puts remote_context.error_message

      write_backtrace(res)

      res.string
    end

    def write_backtrace(res)
      remote_context.error_backtrace.each do |line|
        res.puts
        res.puts "from #{line}"

        next unless (m = stack_trace_regexp.match(line))

        res.puts "(See #{source_path}:#{m[:line_number]}:in #{m[:method_name]}" if source_path
        res.puts format_source(m[:line_number].to_i)
      end
    end
  end
end
