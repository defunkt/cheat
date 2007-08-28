require File.dirname(__FILE__) + '/helper'

context "Order" do
  setup do
    @sql = User.select { |m| m.name == 'jon' }
  end

  specify "simple order" do
    string = @sql.sort_by { |m| m.name }.to_sql
    string.should == "SELECT * FROM users WHERE users.`name` = 'jon' ORDER BY users.name"
  end

  specify "simple combined order" do
    string = @sql.sort_by { |m| [ m.name,  m.age ] }.to_sql
    string.should == "SELECT * FROM users WHERE users.`name` = 'jon' ORDER BY users.name, users.age"
  end

  specify "simple combined order with single reverse" do
    string = @sql.sort_by { |m| [ m.name,  -m.age ] }.to_sql
    string.should == "SELECT * FROM users WHERE users.`name` = 'jon' ORDER BY users.name, users.age DESC"
  end

  specify "simple combined order with two reverses" do
    string = @sql.sort_by { |m| [ -m.name,  -m.age ] }.to_sql
    string.should == "SELECT * FROM users WHERE users.`name` = 'jon' ORDER BY users.name DESC, users.age DESC"
  end

  specify "reverse order with -" do
    string = @sql.sort_by { |m| -m.age }.to_sql
    string.should == "SELECT * FROM users WHERE users.`name` = 'jon' ORDER BY users.age DESC"
  end

  xspecify "reverse order with #reverse" do
    # TODO: not implemented
    string = @sql.sort_by { |m| m.age }.reverse.to_sql
    string.should == "SELECT * FROM users WHERE users.`name` = 'jon' ORDER BY users.age DESC"
  end

  specify "random order" do
    string = @sql.sort_by { rand }.to_sql
    string.should == "SELECT * FROM users WHERE users.`name` = 'jon' ORDER BY RAND()"
  end

  specify "Symbol#to_proc" do
    string = User.sort_by(&:name).to_sql
    string.should == "SELECT * FROM users ORDER BY users.name"
  end
end
