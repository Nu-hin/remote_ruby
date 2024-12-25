# frozen_string_literal: true

require 'open3'

module RemoteRuby
  # An adapter to expecute Ruby code on the local machine
  # inside a temporary file
  class TmpFileAdapter < ::RemoteRuby::ConnectionAdapter
    include Open3

    attr_reader :working_dir, :bundler

    def initialize(working_dir: '.', bundler: false)
      super
      @working_dir = working_dir
      @bundler = bundler
    end

    def open(code)
      with_temp_file(code) do |filename|
        result = nil

        popen3(command(filename)) do |stdin, stdout, stderr, wait_thr|
          @result_fname = stdout.readline.chomp

          yield stdin, stdout, stderr

          result = wait_thr.value
        end

        return if result.success?

        raise "Process exited with code #{result}"
      end
    end

    def with_result_stream(&block)
      File.open(@result_fname, 'r', &block)
    ensure
      File.unlink(@result_fname)
    end

    protected

    def with_temp_file(code)
      Dir.mktmpdir do |dir|
        filename = File.join(dir, 'remote_ruby.rb')
        File.write(filename, code)
        yield filename
      end
    end

    def command(code_path)
      if bundler
        "cd \"#{working_dir}\" && bundle exec ruby #{code_path}"
      else
        "cd \"#{working_dir}\" && ruby #{code_path}"
      end
    end
  end
end
