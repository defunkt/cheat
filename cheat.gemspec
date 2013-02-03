# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cheat/version'

Gem::Specification.new do |spec|
  spec.add_dependency  'pager', '~> 1.0'
  spec.name          = 'cheat'
  spec.description   = "cheat prints cheat sheets from cheat.errtheblog.com, a wiki-like repository of programming knowledge."
  spec.summary       = "cheat prints cheat sheets from cheat.errtheblog.com"
  spec.authors       = ["Chris Wanstrath", "Erik Michaels-Ober"]
  spec.email         = ["chris@ozmm.org", "sferik@gmail.com"]
  spec.bindir        = 'bin'
  spec.executables   = %w(cheat)
  spec.files         = %w(README LICENSE)
  spec.files         += Dir.glob("bin/**/*")
  spec.files         += Dir.glob("lib/**/*")
  spec.files         += Dir.glob("man/**/*")
  spec.files         += Dir.glob("test/**/*")
  spec.homepage      = 'http://cheat.errtheblog.com'
  spec.licenses      = ['MIT']
  spec.require_paths = ['lib']
  spec.required_rubygems_version = '>= 1.3.6'
  spec.version       = Cheat::Version
end
