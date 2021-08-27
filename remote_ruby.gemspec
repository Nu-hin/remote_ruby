# frozen_string_literal: true

require_relative 'lib/remote_ruby/version'

Gem::Specification.new do |spec|
  spec.name          = 'remote_ruby'
  spec.version       = RemoteRuby::VERSION
  spec.authors       = ['Nikita Chernukhin']
  spec.email         = ['nuinuhin@gmail.com']

  spec.summary       = 'Execute Ruby code on the remote servers.'
  spec.description   = 'Execute Ruby code on the remote servers from local Ruby script.'
  spec.homepage      = 'https://github.com/nu-hin/remote_ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.5.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").select do |f|
      f.match(/^(lib|bin)/)
    end
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'method_source', '~> 1.0'
  spec.add_dependency 'parser', '~> 3.0'
  spec.add_dependency 'unparser', '~> 0.6'
end
