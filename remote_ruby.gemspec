lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'remote_ruby/version'

Gem::Specification.new do |spec|
  spec.name          = 'remote_ruby'
  spec.version       = RemoteRuby::VERSION
  spec.authors       = ['Nikita Chernukhin']
  spec.email         = ['nuinuhin@gmail.com']

  spec.summary       = 'Execute Ruby code on the remote servers.'
  spec.description   =
    'Execute Ruby code on the remote servers from local Ruby script.'
  spec.homepage      = 'https://github.com/nu-hin/remote_ruby'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'colorize', '~> 0.8'
  spec.add_runtime_dependency 'method_source', '~> 0.9'
  spec.add_runtime_dependency 'parser', '~> 2.5'
  spec.add_runtime_dependency 'unparser', '~> 0.2'
end
