# frozen_string_literal: true

require_relative 'lib/remote_ruby/version'

Gem::Specification.new do |spec|
  spec.name          = 'remote_ruby'
  spec.version       = RemoteRuby::VERSION
  spec.authors       = ['Nikita Chernukhin']
  spec.email         = ['nuinuhin@gmail.com']

  spec.summary       = 'Execute Ruby code on the remote servers.'
  spec.description   =
    'Execute Ruby code on the remote servers from local Ruby script.'
  spec.homepage      = 'https://github.com/nu-hin/remote_ruby'
  spec.required_ruby_version = '>= 2.7'
  spec.license = 'MIT'

  spec.metadata = {
    'rubygems_mfa_required' => 'true',
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[spec/ .git .github Gemfile])
    end
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'base64', '~> 0.2'
  spec.add_dependency 'colorize', '~> 1.0'
  spec.add_dependency 'logger', '~> 1.6'
  spec.add_dependency 'method_source', '~> 1.1'
  spec.add_dependency 'net-ssh', '~> 7.3'
  spec.add_dependency 'ostruct', '~> 0.6.1'
  spec.add_dependency 'parser', '~> 3.3'
  spec.add_dependency 'unparser', '~> 0.6'
end
