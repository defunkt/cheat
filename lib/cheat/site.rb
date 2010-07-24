#
# According to Wikipedia, Cheat can refer to:
#   Cheating, to take advantage of a situation by the breaking of accepted rules
#     or standards
#   Cheating (casino)
#   Cheating in poker
#   Cheating in online games
#   In relationships, to have an affair
#   A cheat code, a hidden means of gaining an advantage in a video game
#   Cheating, parasitic abuse of symbiotic relationships
#   The Cheat, a character in the cartoon series Homestar Runner
#   Cheat!, a television show on the G4 network
#   The Cheat, a 1915 Cecil B. DeMille movie about a wealthy and domineering
#     Asian gentleman taking advantage of an American female
#   Cheats, a 2002 comedy, starring Matthew Lawrence and Mary Tyler Moore
#   Cheat, a song by The Clash from the UK version of their album The Clash
#   Bullshit, sometimes known as "Cheat," a card game
#   An alternate term for defection in the prisoner's dilemma in game theory
#   Cheat River, a tributary of the Monongahela River in Appalachia; the Cheat
#     starts in West Virginia, and flows westward
#   Cheat Lake, a nearby resevoir
#   Cheat Mountain, one of the highest mountains in the Alleghenies
#
%w[rubygems camping camping/db erb open-uri acts_as_versioned wrap diffr responder ambition].each { |f| require f }
gem 'camping', '>=1.4.152'

Camping.goes :Cheat

# for defunkt. campistrano.
if ARGV.include? '--update'
  ssh = 'ssh deploy@errtheblog.com'
  puts `#{ssh} 'cd /var/www/cheat; svn up'`
  system "#{ssh} 'sudo /etc/init.d/rv restart'"
  exit
end

URL  = ARGV.include?('debug') ? 'http://localhost:8020' : 'http://cheat.errtheblog.com'
FEED = 'http://feeds.feedburner.com/cheatsheets' # rss feed

module Cheat::Models
  class Sheet < Base
    validates_uniqueness_of :title
    validates_format_of     :title, :with => /^[a-z]+[a-z0-9_]*$/i
    validates_presence_of   :title, :body
    before_save { |r| r.title = r.title.gsub(' ', '_').underscore.downcase }
    acts_as_versioned
  end

  class SetUpUsTheCheat < V 1.0
    def self.up
      create_table :cheat_sheets, :force => true do |t|
        t.column :id,         :integer,   :null => false
        t.column :title,      :string,    :null => false
        t.column :body,       :text
        t.column :created_at, :datetime,  :null => false
        t.column :updated_at, :datetime,  :null => false
      end
      Sheet.create_versioned_table
      Sheet.reset_column_information
    end
    def self.down
      drop_table :cheat_sheets
      Sheet.drop_versioned_table
    end
  end
end

module Cheat::Controllers
  class APIShow < R '/y/(\w+)'
    def get(title)
      @headers['Content-Type'] = 'text/plain'

      sheet = Sheet.detect { |s| s.title == title }
      return { 'Error!' => "Cheat sheet `#{title}' not found." }.to_yaml unless sheet

      return { sheet.title => sheet.body }.to_yaml
    end
  end

  class APIRecent < R '/yr'
    def get
      @headers['Content-Type'] = 'text/plain'

      sheets = Sheet.sort_by { |s| -s.created_at }.first(15).map(&:title)
      return { 'Recent Cheat Sheets' => sheets }.to_yaml
    end
  end

  class APIAll < R '/ya'
    def get
      @headers['Content-Type'] = 'text/plain'

      sheets = Sheet.sort_by(&:title).map(&:title)
      return { 'All Cheat Sheets' => sheets }.to_yaml
    end
  end

  class Feed < R '/f'
    def get
      @headers['Content-Type'] = 'application/xml'
      return Cheat::Views.feed
    end
  end

  class Index < R '/'
    def get
      render :index
    end
  end

  class Add < R '/a'
    def get
      @sheet = Sheet.new
      render :add
    end
  end

  class Edit < R '/e/(\w+)/(\d+)', '/e/(\w+)'
    def get(title, version = nil)
      @sheet = Sheet.detect { |s| s.title == title }

      @error = "Cheat sheet not found." unless @sheet
      unless version.nil? || version == @sheet.version.to_s
        @sheet = @sheet.find_version(version)
      end
      render @error ? :error : :edit
    end
  end

  class Write < R '/w', '/w/(\w+)'
    def post(title = nil)
      @sheet = title ? Sheet.find_by_title(title) : Sheet.new
      @sheet = title ? Sheet.detect { |s| s.title == title } : Sheet.new

      check_captcha! unless input.from_gem

      if !@error && @sheet.update_attributes(:title => input.sheet_title, :body => input.sheet_body)
        redirect "#{URL}/s/#{@sheet.title}"
      else
        @error = true
        render title ? :edit : :add
      end
    end

    def check_captcha!
      @error ||= !(@cookies[:passed] ||= captcha_pass?(input.chunky, input.bacon))
    end

    def captcha_pass?(session, answer)
      open("http://captchator.com/captcha/check_answer/#{session}/#{answer}").read.to_i.nonzero? rescue false
    end
  end

  class Browse < R '/b'
    def get
      @sheets = Sheet.sort_by(&:title)
      render :browse
    end
  end

  class Show < R '/s/(\w+)', '/s/(\w+)/(\d+)'
    def get(title, version = nil)
      @sheet = Sheet.detect { |s| s.title == title }
      @sheet = @sheet.find_version(version) if version && @sheet

      @sheet ? render(:show) : redirect("#{URL}/b/")
    end
  end

  # we are going to start consolidating classes with respond_to and what not.
  # diff is the first, as the api and the site will use the same code
  class Diff < R '/d/(\w+)/(\d+)', '/d/(\w+)/(\d+)/(\d+)'
    include Responder

    def get(title, old_version, new_version = nil)
      redirect "#{URL}/b/" and return unless old_version.to_i.nonzero?

      @sheet = Sheet.detect { |s| s.title == title }
      @old_sheet = @sheet.find_version(old_version)
      @new_sheet = (new_version ? @sheet.find_version(new_version) : @sheet)

      @diffed = Diffr.diff(@old_sheet, @new_sheet) rescue nil

      respond_to do |wants|
        wants.html { render :diff }
        wants.yaml { { @sheet.title => @diffed }.to_yaml }
      end
    end
  end

  class History < R '/h/(\w+)'
    include Responder

    def get(title)
      if sheets = Sheet.detect { |s| s.title == title }
        @sheets = sheets.find_versions(:order => 'version DESC')
      end

      respond_to do |wants|
        wants.html { render :history }
        wants.yaml { { @sheets.first.title => @sheets.map(&:version) }.to_yaml }
      end
    end
  end
end

module Cheat::Views
  def layout
    html {
      head {
        _style
        link :href => FEED, :rel => "alternate", :title => "Recently Updated Cheat Sheets", :type => "application/atom+xml"
        title @page_title ? "$ cheat #{@page_title}" : "$ command line ruby cheat sheets"
      }
      body {
        div.main {
          div.header {
            h1 { logo_link 'cheat sheets.' }
            code.header @sheet_title ? "$ cheat #{@sheet_title}" : "$ command line ruby cheat sheets"
            }
          div.content { self << yield }
          div.side { _side }
          div.clear { '' }
          div.footer { _footer }
        }
        _clicky
      }
    }
  end

  def _clicky
    text '<script src="http://getclicky.com/1070.js"> </script><noscript><img height=0 width=0 src="http://getclicky.com/1070ns.gif"></noscript>'
  end

  def error
    @page_title = "error"
    p "An error:"
    code.version @error
    p ":("
  end

  def show
    @page_title = @sheet.title
    @sheet_title = @sheet.title
    pre.sheet { text h(@sheet.body.wrap) }
    div.version {
      text "Version "
      strong sheet.version
      text ", updated "
      text last_updated(@sheet)
      text " ago.  "
      br
      text ". o 0 ( "
      if @sheet.version == current_sheet.version
        a "edit", :href => R(Edit, @sheet.title)
      end
      if @sheet.version > 1
        text " | "
        a "previous", :href => R(Show, @sheet.title, @sheet.version - 1)
      end
      text " | "
      a "history", :href => R(History, @sheet.title)
      unless @sheet.version == current_sheet.version
        text " | "
        a "revert to", :href => R(Edit, @sheet.title, @sheet.version)
        text " | "
        a "current", :href => R(Show, @sheet.title)
      end
      diff_version =
        if @sheet.version == current_sheet.version
          @sheet.version == 1 ? nil : @sheet.version - 1
        else
          @sheet.version
        end
      if diff_version
        text " | "
        a "diff", :href => R(Diff, @sheet.title, diff_version)
      end
      text " )"
     }
  end

  def diff
    @page_title = @sheet.title
    @sheet_title = @sheet.title
    pre.sheet { color_diff(h(@diffed)) if @diffed }
    div.version {
      text ". o 0 ("
      if @old_sheet.version > 1
        a "diff previous", :href => R(Diff, @sheet.title, @old_sheet.version - 1)
        text " | "
      end
      a "history", :href => R(History, @sheet.title)
      text " | "
      a "current", :href => R(Show, @sheet.title)
      text " )"
    }
  end

  def browse
    @page_title = "browse"
    p { "Wowzers, we've got <strong>#{@sheets.size}</strong> cheat sheets hereabouts." }
    ul {
      @sheets.each do |sheet|
        li { sheet_link sheet.title }
      end
    }
    p {
      text "Are we missing a cheat sheet?  Why don't you do the whole world a favor and "
      a "add it", :href => R(Add)
      text " yourself!"
    }
  end

  def history
    @page_title  = "history"
    @sheet_title = @sheets.first.title
    h2 @sheets.first.title
    ul {
      @sheets.each_with_index do |sheet, i|
        li {
          a "version #{sheet.version}", :href => R(Show, sheet.title, sheet.version)
          text " - created "
          text last_updated(sheet)
          text " ago"
          strong " (current)" if i.zero?
          text " "
          a "(diff to current)", :href => R(Diff, sheet.title, sheet.version) if i.nonzero?
        }
      end
    }
  end

  def add
    @page_title = "add"
    p {
      text "Thanks for wanting to add a cheat sheet.  If you need an example of
       the standard cheat sheet format, check out the "
       a "cheat", :href => R(Show, 'cheat')
       text " cheat sheet.  (There's really no standard format, though)."
     }
    _form
  end

  def edit
    @page_title = "edit"
    _form
  end

  def _form
    if @error
      p.error {
        strong "HEY!  "
        text "Something is wrong!  You can't give your cheat sheet the same name
              as another, alphanumeric titles only, and you need to make sure
              you filled in all (two) of the fields.  Okay?"
      }
    end
    form :method => 'post', :action => R(Write, @sheet.title) do
      p {
        p {
          text 'Cheat Sheet Title: '
          input :value => @sheet.title, :name => 'sheet_title', :size => 30,
                :type => 'text'
          small " [ no_spaces_alphanumeric_only ]"
        }
        p {
          text 'Cheat Sheet:'
          br
          textarea @sheet.body, :name => 'sheet_body', :cols => 80, :rows => 30
          unless @cookies[:passed]
            random = rand(10_000)
            br
            img :src => "http://captchator.com/captcha/image/#{random}"
            input :name => 'chunky', :type => 'hidden', :value => random
            input :name => 'bacon', :size => 10, :type => 'text'
          end
        }
      }
      p "Your cheat sheet will be editable (fixable) by anyone.  Each cheat
         sheet is essentially a wiki page.  It may also be used by millions of
         people for reference purposes from the comfort of their command line.
         If this is okay with you, please save."
      input :value => "Save the Damn Thing!", :name => "save", :type => 'submit'
    end
  end

  def index
    p {
      text "Welcome.  You've reached the central repository for "
      strong "cheat"
      text ", the RubyGem which puts Ruby-centric cheat sheets right into your
            terminal.  The inaugural blog entry "
      a "is here", :href => "http://errtheblog.com/post/23"
      text "."
    }
    p "Get started:"
    code "$ gem install cheat"
    br
    code "$ cheat strftime"
    p "A magnificent cheat sheet for Ruby's strftime method will be printed to
       your terminal."
    p "To get some help on cheat itself:"
    code "$ cheat cheat"
    p "How meta."
    p {
      text "Cheat sheets are basically wiki pages accessible from the command
            line.  You can "
      a 'browse', :href => R(Browse)
      text ', '
      a 'add', :href => R(Add)
      text ', or '
      a 'edit', :href => R(Edit, 'cheat')
      text ' cheat sheets.  Try to keep them concise.  For a style guide, check
            out the '
      a 'cheat', :href => R(Edit, 'cheat')
      text ' cheat sheet.'
    }
    p "To access a cheat sheet, simply pass the program the desired sheet's
       name:"
    code "$ cheat <sheet name>"
    p
  end

  def self.feed
    xml = Builder::XmlMarkup.new(:indent => 2)

    xml.instruct!
    xml.feed "xmlns"=>"http://www.w3.org/2005/Atom" do

      xml.title "Recently Updated Cheat Sheets"
      xml.id URL + '/'
      xml.link "rel" => "self", "href" => FEED

      sheets = Cheat::Models::Sheet.sort_by { |s| -s.updated_at }.first(20)
      xml.updated sheets.first.updated_at.xmlschema

      sheets.each do |sheet|
        xml.entry do
          xml.id URL + '/s/' + sheet.title
          xml.title sheet.title
          xml.author { xml.name "An Anonymous Cheater" }
          xml.updated sheet.updated_at.xmlschema
          xml.link "rel" => "alternate", "href" => URL + '/s/' + sheet.title
          xml.summary "A cheat sheet about #{sheet.title}.  Run it: `$ cheat #{sheet.title}'"
          xml.content 'type' => 'html' do
            xml.text! sheet.body.gsub("\n", '<br/>').gsub("\r", '')
          end
        end
      end
    end
  end

  def _side
    text '( '
    a 'add new', :href => R(Add)
    text ' | '
    a 'see all', :href => R(Browse)
    text ' )'
    ul {
      li { strong "updated sheets" }
      li do
        a :href => FEED do
          img(:border => 0, :alt => "Recently Updated Cheat Sheets Feed", :src => "http://errtheblog.com/images/feed.png")
        end
      end
      recent_sheets.each do |sheet|
        li { sheet_link sheet.title }
      end
    }
  end

  def _footer
    text "Powered by "
    a 'Camping', :href => "http://code.whytheluckystiff.net/camping"
    text ", "
    a 'Mongrel', :href => "http://mongrel.rubyforge.org/"
    text " and, to a lesser extent, "
    a 'Err the Blog', :href => "http://errtheblog.com/"
    text "."
  end

  def _style
    bg    = "#fff"
    h1    = "#4fa3da"
    link  = h1
    hover = "#f65077"
    dash  = hover
    version = "#fcf095"
    style :type => "text/css" do
      text %[
        body { font-family: verdana, sans-serif; background-color: #{bg};
               line-height: 20px; }
        a:link, a:visited { color: #{link}; }
        a:hover { text-decoration: none; color: #{hover}; }
        div.header { border-bottom: 1px dashed #{dash}; }
        code.header { margin-left: 30px; font-weight: bold;
                      background-color: #{version}; }
        h1 { font-size: 5em; margin: 0; padding-left: 30px; color: #{h1};
             clear: both; font-weight: bold; letter-spacing: -5px; }
        h1 a { text-decoration: none; }
        div.main    { float: left; width: 100%; }
        div.content { float: left; width: 70%; padding: 15px 0 15px 30px;
                      line-height: 20px; }
        div.side    { float: left; padding: 10px; text-align: right;
                      width: 20%; }
        div.footer  { text-align: center; border-top: 1px dashed #{dash};
                      padding-top: 10px; font-size: small; }
        div.sheet { font-size: .8em; line-height: 17px; padding: 5px;
                    font-family: courier, fixed-width; background-color: #e8e8e8; }
        pre.sheet { line-height: 15px; }
        li { list-style: none; }
        div.version { background-color: #{version}; padding: 5px;
                       width: 450px; margin-top: 50px; }
        p.error { background-color: #{version}; padding: 5px; }
        div.clear    { clear: both; }
        div.clear_10 { clear: both; font-size: 10px; line-height: 10px; }
        textarea { font-family: courier; }
        code { background-color: #{version} }
        span.diff_cut { color: #f65077; }
        span.diff_add { color: #009933; }
        @media print {
          .side, .version, .footer { display: none; }
          div.content { width: 100%; }
          h1 a:link, h1 a:visited { color: #eee;}
          .header code { font-size: 18px; background: none; }
          div.header { border-bottom: none; }
        }
      ].gsub(/(\s{2,})/, '').gsub("\n", '')
    end
  end
end

module Cheat::Helpers
  def logo_link(title)
    ctr = Cheat::Controllers
    if @sheet && !@sheet.new_record? && @sheet.version != current_sheet.version
      a title, :href => R(ctr::Show, @sheet.title)
    else
      a title, :href => R(ctr::Index)
    end
  end

  def current_sheet
    title = @sheet.title
    @current_sheet ||= Cheat::Models::Sheet.detect { |s| s.title == title }
  end

  def recent_sheets
    Cheat::Models::Sheet.sort_by { |s| -s.updated_at }.first(15)
  end

  def sheet_link(title, version = nil)
    a title, :href => R(Cheat::Controllers::Show, title, version)
  end

  def last_updated(sheet)
    from = sheet.updated_at.to_i
    to = Time.now.to_i
    from = from.to_time if from.respond_to?(:to_time)
    to = to.to_time if to.respond_to?(:to_time)
    distance = (((to - from).abs)/60).round
    case distance
      when 0..1       then return (distance==0) ? 'less than a minute' : '1 minute'
      when 2..45      then "#{distance} minutes"
      when 46..90     then 'about 1 hour'
      when 90..1440   then "about #{(distance.to_f / 60.0).round} hours"
      when 1441..2880 then '1 day'
      else                 "#{(distance / 1440).round} days"
    end
  end

  def self.h(text)
    ERB::Util::h(text)
  end

  def h(text)
    ::Cheat::Helpers.h(text)
  end

  def color_diff(diff)
    diff.split("\n").map do |line|
      action = case line
               when /^-/  then 'cut'
               when /^\+/ then 'add'
               end
      action ? span.send("diff_#{action}", line) : line
    end * "\n"
  end
end

def Cheat.create
  Cheat::Models.create_schema
end

if __FILE__ == $0
  begin
    require 'mongrel/camping'
  rescue LoadError => e
    abort "** Try running `camping #$0' instead."
  end

  Cheat::Models::Base.establish_connection :adapter => 'mysql', :user => 'root', :database => 'camping', :host => 'localhost'
  Cheat::Models::Base.logger = nil
  Cheat::Models::Base.threaded_connections = false
  Cheat.create

  server = Mongrel::Camping.start("0.0.0.0", 8020, "/", Cheat)
  puts "** Cheat is running at http://0.0.0.0:8020/"
  server.run.join
end
