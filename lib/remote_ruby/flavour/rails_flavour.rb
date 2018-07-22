module RemoteRuby
  # Flavour to load Rails environment
  class RailsFlavour < ::RemoteRuby::Flavour
    def initialize(environment: :development)
      @environment = environment
    end

    def code_header
      <<-RUBY
  ENV['RAILS_ENV'] = '#{environment}'
  require './config/environment'
      RUBY
    end

    private

    attr_reader :environment
  end
end
