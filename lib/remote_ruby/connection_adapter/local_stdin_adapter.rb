# frozen_string_literal: true

module RemoteRuby
  # An adapter to expecute Ruby code on the local macine
  # inside a specified directory
  class LocalStdinAdapter < ::RemoteRuby::StdinProcessAdapter
    attr_reader :working_dir

    def initialize(working_dir: '.')
      super
      @working_dir = working_dir
    end

    def connection_name
      working_dir
    end

    private

    def command
      "cd \"#{working_dir}\" && ruby"
    end
  end
end
