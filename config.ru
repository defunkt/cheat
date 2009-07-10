$LOAD_PATH.unshift 'lib'
require 'site'
run Rack::Adapter::Camping.new(Cheat)
