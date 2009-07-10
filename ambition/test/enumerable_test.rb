require File.dirname(__FILE__) + '/helper'

context "Each" do
  specify "simple ==" do
    hash = { :conditions => "users.`age` = 21" }
    User.expects(:find).with(:all, hash).returns([])
    User.select { |m| m.age == 21 }.each do |user|
      puts user.name
    end
  end

  specify "limit and conditions" do
    hash = { :limit => '5', :conditions => "users.`age` = 21" }
    User.expects(:find).with(:all, hash).returns([])
    User.select { |m| m.age == 21 }.first(5).each do |user|
      puts user.name
    end
  end

  specify "limit and conditions and order" do
    hash = { :limit => '5', :conditions => "users.`age` = 21", :order => 'users.name' }
    User.expects(:find).with(:all, hash).returns([])
    User.select { |m| m.age == 21 }.sort_by { |m| m.name }.first(5).each do |user|
      puts user.name
    end
  end

  specify "limit and order" do
    hash = { :limit => '5', :order => 'users.name' }
    User.expects(:find).with(:all, hash).returns([])
    User.sort_by { |m| m.name }.first(5).each do |user|
      puts user.name
    end
  end
end

context "Enumerable Methods" do
  specify "map" do
    hash = { :conditions => "users.`age` = 21" }
    User.expects(:find).with(:all, hash).returns([])
    User.select { |m| m.age == 21 }.map { |u| u.name }
  end

  specify "each_with_index" do
    hash = { :conditions => "users.`age` = 21" }
    User.expects(:find).with(:all, hash).returns([])
    User.select { |m| m.age == 21 }.each_with_index do |user, i|
      puts "#{i}: #{user.name}"
    end
  end
end
