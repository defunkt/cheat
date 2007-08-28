require 'rubygems'
require 'proc_to_ruby'
require 'ambition/processor'
require 'ambition/query'
require 'ambition/where'
require 'ambition/order'
require 'ambition/limit'
require 'ambition/count'
require 'ambition/enumerable'

module Ambition 
  include Where, Order, Limit, Enumerable, Count

  attr_accessor :query_context

  def query_context
    @query_context || Query.new(self)
  end
end

ActiveRecord::Base.extend Ambition
