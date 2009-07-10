require File.dirname(__FILE__) + '/helper'

##
# Once dynamically, once hardcoded
context "Different types" do
  types_hash = {
    'string' => "'string'",
    :symbol  => "'--- :symbol\n'",
    1        => '1',
    1.2      => '1.2',
    nil      => 'NULL',
    true     => '1',
    false    => '0',
    Time.now     => "'#{Time.now.to_s(:db)}'",
    DateTime.now => "'#{DateTime.now.to_s(:db)}'",
    Date.today   => "'#{Date.today.to_s(:db)}'"
  }

  types_hash.each do |type, translation|
    specify "simple using #{type}" do
      sql = User.select { |m| m.name == type }.to_sql
      sql.should == "SELECT * FROM users WHERE users.`name` = #{translation}"
    end
  end

  specify "float" do
    sql = User.select { |m| m.name == 1.2 }.to_sql
    sql.should == "SELECT * FROM users WHERE users.`name` = 1.2"
  end

  specify "integer" do
    sql = User.select { |m| m.name == 1 }.to_sql
    sql.should == "SELECT * FROM users WHERE users.`name` = 1"
  end

  specify "true" do
    sql = User.select { |m| m.name == true }.to_sql
    sql.should == "SELECT * FROM users WHERE users.`name` = 1"
  end

  specify "false" do
    sql = User.select { |m| m.name == false }.to_sql
    sql.should == "SELECT * FROM users WHERE users.`name` = 0"
  end

  specify "nil" do
    sql = User.select { |m| m.name == nil }.to_sql
    sql.should == "SELECT * FROM users WHERE users.`name` = NULL"
  end

  xspecify "Time" do
    # TODO: nothing but variables inside blocks for now
    sql = User.select { |m| m.name == Time.now }.to_sql
    sql.should == "SELECT * FROM users WHERE users.`name` = NULL"
  end
end
