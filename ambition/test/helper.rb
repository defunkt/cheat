require 'rubygems'
require 'test/spec'
require 'mocha'
require 'redgreen'
require 'active_support'
require 'active_record'

$:.unshift File.dirname(__FILE__) + '/../lib'
require 'ambition'

class User
  extend Ambition

  def self.reflections
    return @reflections if @reflections
    @reflections = {}
    @reflections[:ideas]    = Reflection.new(:has_many,   'user_id',     :ideas,   'ideas')
    @reflections[:invites]  = Reflection.new(:has_many,   'referrer_id', :invites, 'invites')
    @reflections[:profile]  = Reflection.new(:has_one,    'user_id',     :profile, 'profiles')
    @reflections[:account]  = Reflection.new(:belongs_to, 'account_id',  :account, 'accounts')
    @reflections
  end

  def self.table_name
    'users'
  end
end

class Reflection < Struct.new(:macro, :primary_key_name, :name, :table_name)
end
