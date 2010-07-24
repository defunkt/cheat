
# Example mongrel harness for camping apps with rv
#
# author: Evan Weaver
# url: http://blog.evanweaver.com/articles/2006/12/19/rv-a-tool-for-luxurious-camping
# license: AFL 3.0

require 'mongrel'
require 'mongrel/camping'
LOGFILE = 'mongrel.log'
PIDFILE = 'mongrel.pid'

# or whatever else you want passed in
PORT = ARGV[0].to_i
ADDR = ARGV[1]

# this is your camping app
require 'site'
app = Cheat

# custom database configuration
app::Models::Base.establish_connection :adapter => 'mysql', :user => 'root', :database => 'camping', :host => 'localhost'

app::Models::Base.logger = nil
app::Models::Base.threaded_connections = false
app.create

config = Mongrel::Configurator.new :host => ADDR, :pid_file => PIDFILE do
  listener :port => PORT do
    uri '/', :handler => Mongrel::Camping::CampingHandler.new(app)
    # use the mongrel static server in production instead of the camping controller
    uri '/static/', :handler => Mongrel::DirHandler.new("static/")
    uri '/favicon.ico', :handler => Mongrel::Error404Handler.new('')
    setup_signals
    run
    write_pid_file
    log "#{app} available at #{ADDR}:#{PORT}"
    join
  end
end

