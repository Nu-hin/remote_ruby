# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

group :development do
  gem 'rubocop', '~> 1.23'
  gem 'yard', '~> 0.9'
end

group :development, :test do
  gem 'byebug', '~> 11.1'
  gem 'pry-byebug', '~> 3.9'
  gem 'rspec', '~> 3.10'
end

group :test do
  gem 'coveralls' ,'~> 0.8', require: false
end
