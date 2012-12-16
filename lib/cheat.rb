%w( tempfile fileutils net/http yaml open-uri cheat/wrap ).each { |f| require f }
require 'pager'
RUBY_PLATFORM = PLATFORM unless defined? RUBY_PLATFORM   # Ruby 1.8 compatibility

def mswin?
  (RUBY_PLATFORM =~ /(:?mswin|mingw)/) || (RUBY_PLATFORM == 'java' && (ENV['OS'] || ENV['os']) =~ /windows/i)
end

module Cheat
  include Pager
  extend self

  HOST = ARGV.include?('debug') ? 'localhost' : 'cheat.errtheblog.com'
  PORT = ARGV.include?('debug') ? 3001 : 80
  SUFFIX = ''

  def sheets(args)
    args = args.dup

    return unless parse_args(args)

    FileUtils.mkdir(cache_dir) unless File.exists?(cache_dir) if cache_dir

    uri = "http://#{cheat_uri}/y/"

    if @offline
      return process(File.read(cache_file)) if File.exists?(cache_file) rescue clear_cache if cache_file
    else
      if %w[sheets all recent].include? @sheet
        uri = uri.sub('/y/', @sheet == 'recent' ? '/yr/' : '/ya/')
        return open(uri, headers) { |body| process(body.read) }
      end
      return process(File.read(cache_file)) if File.exists?(cache_file) rescue clear_cache if cache_file
      fetch_sheet(uri + @sheet) if @sheet
    end
  end

  def fetch_sheet(uri, try_to_cache = true)
    open(uri, headers) do |body|
      sheet = body.read
      FileUtils.mkdir_p(cache_dir) unless File.exists?(cache_dir)
      File.open(cache_file, 'w') { |f| f.write(sheet) } if try_to_cache && has_content(sheet) && cache_file && !@edit
      @edit ? edit(sheet) : show(sheet)
    end
    exit
  rescue OpenURI::HTTPError => e
    puts "Whoa, some kind of Internets error!", "=> #{e} from #{uri}"
  end

  def parse_args(args)
    puts "Looking for help?  Try http://cheat.errtheblog.com or `$ cheat cheat'" and return if args.empty?

    if args.delete('--clear-cache') || args.delete('--new')
      clear_cache
      return if args.empty?
    end

    if i = args.index('--diff')
      diff_sheets(args.first, args[i+1])
    end

    show_versions(args.first) if args.delete('--versions')

    list if args.delete('--list')

    add(args.shift) and return if args.delete('--add')
    incoming_file = true if @edit = args.delete('--edit')

    @execute = true if args.delete("--execute") || args.delete("-x")
    # use offline (use cached versions only) if no active connection to internet
    @offline = true if args.delete("--local") || args.delete("-l")
    @sheet = args.shift

    clear_cache_file if incoming_file
    true
  end

  # $ cheat greader --versions
  def show_versions(sheet)
    fetch_sheet("http://#{cheat_uri}/h/#{sheet}/", false)
  end

  # $ cheat greader --diff 1[:3]
  def diff_sheets(sheet, version)
    return unless version =~ /^(\d+)(:(\d+))?$/
    old_version, new_version = $1, $3

    uri = "http://#{cheat_uri}/d/#{sheet}/#{old_version}"
    uri += "/#{new_version}" if new_version

    fetch_sheet(uri, false)
  end

  def has_content(sheet)
    if sheet.is_a?(String)
      return (sheet.length > 15) && !sheet[0,14].include?("Error!")
    end
    return true
  end

  def cache_file
    "#{cache_dir}/#{@sheet}.yml" if cache_dir
  end

  def headers
    { 'User-Agent' => 'cheat!', 'Accept' => 'text/yaml' }
  end

  def cheat_uri
    "#{HOST}:#{PORT}#{SUFFIX}"
  end

  def execute(sheet_yaml)
    sheet_body = YAML.load(sheet_yaml).to_a.flatten.last
    puts "\n  " + sheet_body.gsub("\r",'').gsub("\n", "\n  ").wrap
    puts "\nWould you like to execute the above sheet? (Y/N)"
    answer = STDIN.gets
    case answer.chomp
    when "Y" then system YAML.load(sheet_yaml).to_a.flatten.last
    when "N" then puts "Not executing sheet."
    else
      puts "Must be Y or N!"
    end
  rescue Errno::EPIPE
    # do nothing
  rescue
    puts "That didn't work.  Maybe try `$ cheat cheat' for help?" # Fix Emacs ruby-mode highlighting bug: `"
  end

  def process(sheet_yaml)
    if @execute
      execute(sheet_yaml)
    else
      show(sheet_yaml)
    end
  end

  def list
    if cache_dir
      d = Dir.glob "#{cache_dir}/#{@sheet}*.yml"
      d.each {|f| puts File.basename(f, ".yml")}
    end
  end

  def show(sheet_yaml)
    sheet = YAML.load(sheet_yaml).to_a.first
    sheet[-1] = sheet.last.join("\n") if sheet[-1].is_a?(Array)
    page
    puts sheet.first + ':'
    puts '  ' + sheet.last.gsub("\r",'').gsub("\n", "\n  ").wrap
  rescue Errno::EPIPE
    # do nothing
  rescue
    puts "That didn't work.  Maybe try `$ cheat cheat' for help?" # Fix Emacs ruby-mode highlighting bug: `"
  end

  def edit(sheet_yaml)
    sheet = YAML.load(sheet_yaml).to_a.first
    sheet[-1] = sheet.last.gsub("\r", '')
    body, title = write_to_tempfile(*sheet), sheet.first
    return if body.strip == sheet.last.strip
    res = post_sheet(title, body)
    check_errors(res, title, body)
  end

  def add(title)
    body = write_to_tempfile(title)
    res = post_sheet(title, body, true)
    check_errors(res, title, body)
  end

  def post_sheet(title, body, new = false)
    uri = "http://#{cheat_uri}/w/"
    uri += title unless new
    Net::HTTP.post_form(URI.parse(uri), "sheet_title" => title, "sheet_body" => body.strip, "from_gem" => true)
  end

  def write_to_tempfile(title, body = nil)
    # god dammit i hate tempfile, this is so messy but i think it's
    # the only way.
    tempfile = Tempfile.new(title + '.cheat')
    tempfile.write(body) if body
    tempfile.close
    system "#{editor} #{tempfile.path}"
    tempfile.open
    body = tempfile.read
    tempfile.close
    body
  end

  def check_errors(result, title, text)
    if result.body =~ /<p class="error">(.+?)<\/p>/m
      puts $1.gsub(/\n/, '').gsub(/<.+?>/, '').squeeze(' ').wrap(80)
      puts
      puts "Here's what you wrote, so it isn't lost in the void:"
      puts text
    else
      puts "Success!  Try it!", "$ cheat #{title}"
    end
  end

  def editor
    ENV['VISUAL'] || ENV['EDITOR'] || "vim"
  end

  def cache_dir
    mswin? ? win32_cache_dir : File.join(File.expand_path("~"), ".cheat")
  end

  def win32_cache_dir
    unless File.exists?(home = ENV['HOMEDRIVE'] + ENV['HOMEPATH'])
      puts "No HOMEDRIVE or HOMEPATH environment variable.  Set one to save a" +
           "local cache of cheat sheets."
      return false
    else
      return File.join(home, 'Cheat')
    end
  end

  def clear_cache
    FileUtils.rm_rf(cache_dir) if cache_dir
  end

  def clear_cache_file
    FileUtils.rm(cache_file) if File.exists?(cache_file)
  end

end

Cheat.sheets(ARGV) if __FILE__ == $0
