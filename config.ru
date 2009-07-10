$LOAD_PATH.unshift 'lib'
require 'rack'
require 'site'
run Rack::Adapters::Camping.new(Cheat)
