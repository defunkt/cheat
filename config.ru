$LOAD_PATH.unshift 'lib'
require 'site'
run Rack::Adapters::Camping.new(Cheat)
