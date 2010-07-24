$LOAD_PATH.unshift 'lib'
require "cheat/version"

Gem::Specification.new do |s|
  s.name              = "cheat"
  s.version           = Cheat::VERSION
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "cheat prints cheat sheets from cheat.errtheblog.com"
  s.homepage          = "http://cheat.errtheblog.com"
  s.email             = "chris@ozmm.org"
  s.authors           = [ "Chris Wanstrath" ]
  s.has_rdoc          = false

  s.files             = %w( README LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")
  s.files            += Dir.glob("man/**/*")
  s.files            += Dir.glob("test/**/*")

  s.executables       = %w( cheat )
  s.description       = <<desc
  cheat prints cheat sheets from cheat.errtheblog.com, a wiki-like
  repository of programming knowledge.
desc
end
