# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'remote_ruby/version'

Gem::Specification.new do |spec|
  spec.name          = 'remote_ruby'
  spec.version       = RemoteRuby::VERSION
  spec.authors       = ['Nikita Chernukhin']
  spec.email         = ['nuinuhin@gmail.com']

  spec.metadata = {
    'rubygems_mfa_required' => 'true'
  }

  spec.required_ruby_version = '>= 2.6'

  spec.summary       = 'Execute Ruby code on the remote servers.'
  spec.description   =
    'Execute Ruby code on the remote servers from local Ruby script.'
  spec.homepage      = 'https://github.com/nu-hin/remote_ruby'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'base64', '~> 0.2'
  spec.add_dependency 'colorize', '~> 0.8'
  spec.add_dependency 'method_source', '~> 1.0'
  spec.add_dependency 'parser', '~> 3.0'
  spec.add_dependency 'unparser', '~> 0.6'
end
