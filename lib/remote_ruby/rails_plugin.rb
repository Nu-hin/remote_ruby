# frozen_string_literal: true

module RemoteRuby
  # Plugin to load Rails environment
  class RailsPlugin < ::RemoteRuby::Plugin
    def initialize(environment: :development)
      super
      @environment = environment
    end

    def code_header
      <<~RUBY
        ENV['RAILS_ENV'] = '#{environment}'
        require './config/environment'
      RUBY
    end

    private

    attr_reader :environment
  end
end
