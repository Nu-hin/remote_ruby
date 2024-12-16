# frozen_string_literal: true

module RemoteRuby
  # An adapter to expecute Ruby code on the local macine
  # inside a specified directory
  class LocalStdinAdapter < ::RemoteRuby::StdinProcessAdapter
    attr_reader :working_dir, :bundler

    def initialize(working_dir: '.', bundler: false)
      super
      @working_dir = working_dir
      @bundler = bundler
    end

    private

    def command
      if bundler
        "cd \"#{working_dir}\" && bundle exec ruby"
      else
        "cd \"#{working_dir}\" && ruby"
      end
    end
  end
end
