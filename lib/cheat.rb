$:.unshift File.dirname(__FILE__)
%w[rubygems tempfile fileutils net/http yaml open-uri wrap].each { |f| require f }

module Cheat
  extend self

  HOST = ARGV.include?('debug') ? 'localhost' : 'cheat.errtheblog.com'
  PORT = ARGV.include?('debug') ? 3001 : 80
  SUFFIX = ''

  def sheets(args)
    args = args.dup

    return unless parse_args(args)

    FileUtils.mkdir(cache_dir) unless File.exists?(cache_dir) if cache_dir

    uri = "http://#{cheat_uri}/y/"

    if %w[sheets all recent].include? @sheet
      uri = uri.sub('/y/', @sheet == 'recent' ? '/yr/' : '/ya/')
      return open(uri) { |body| show(body.read) } 
    end

    return show(File.read(cache_file)) if File.exists?(cache_file) rescue clear_cache if cache_file 

    fetch_sheet(uri + @sheet) if @sheet
  end

  def fetch_sheet(uri, try_to_cache = true)
    open(uri, headers) do |body|
      sheet = body.read
      File.open(cache_file, 'w') { |f| f.write(sheet) } if try_to_cache && cache_file && !@edit 
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

    add(args.shift) and return if args.delete('--add')
    clear_cache if @edit = args.delete('--edit')

    @sheet = args.shift

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

  def cache_file
    "#{cache_dir}/#{@sheet}.yml" if cache_dir
  end

  def headers
    { 'User-Agent' => 'cheat!', 'Accept' => 'text/yaml' } 
  end

  def cheat_uri
    "#{HOST}:#{PORT}#{SUFFIX}"
  end

  def show(sheet_yaml)
    sheet = YAML.load(sheet_yaml).to_a.first
    sheet[-1] = sheet.last.join("\n") if sheet[-1].is_a?(Array)
    puts sheet.first + ':'
    puts '  ' + sheet.last.gsub("\r",'').gsub("\n", "\n  ").wrap
  rescue
    puts "That didn't work.  Maybe try `$ cheat cheat' for help?"
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
      puts "Success!  Try it!", "$ cheat #{title} --new"
    end
  end

  def editor
    ENV['VISUAL'] || ENV['EDITOR'] || "vim" 
  end

  def cache_dir
    PLATFORM =~ /win32/ ? win32_cache_dir : File.join(File.expand_path("~"), ".cheat")
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
end

Cheat.sheets(ARGV) if __FILE__ == $0
