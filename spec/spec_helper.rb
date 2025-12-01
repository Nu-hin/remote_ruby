# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'

REMOTE_RUBY_RSPEC_RUNNING = true

SimpleCov.start do
  if ENV['CI']
    require 'simplecov-lcov'

    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      c.single_report_path = 'coverage/lcov.info'
    end

    formatter SimpleCov::Formatter::LcovFormatter
  end

  add_filter 'spec/integration/ssh_spec.rb'
  add_filter 'spec/integration/config.rb'
end
require 'remote_ruby'

require_relative 'integration/config'

Bundler.require(:development, :test)

require_relative 'support/test_adapter'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_including(focus: true)
  config.run_all_when_everything_filtered = true
end
