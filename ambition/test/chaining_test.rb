require File.dirname(__FILE__) + '/helper'

context "Chaining" do
  specify "should join selects with AND" do
    sql = User.select { |m| m.name == 'jon' }
    sql = sql.select { |m| m.age == 22 }
    sql.to_sql.should == "SELECT * FROM users WHERE users.`name` = 'jon' AND users.`age` = 22"
  end

  specify "should join sort_bys with a comma" do
    sql = User.select { |m| m.name == 'jon' }
    sql = sql.sort_by { |m| m.name }
    sql = sql.sort_by { |m| m.age }
    sql.to_sql.should == "SELECT * FROM users WHERE users.`name` = 'jon' ORDER BY users.name, users.age"
  end

  specify "should join selects and sorts intelligently" do
    sql = User.select { |m| m.name == 'jon' }
    sql = sql.select { |m| m.age == 22 }
    sql = sql.sort_by { |m| -m.name }
    sql = sql.sort_by { |m| m.age }
    sql.to_sql.should == "SELECT * FROM users WHERE users.`name` = 'jon' AND users.`age` = 22 ORDER BY users.name DESC, users.age"
  end

  specify "should join lots of selects and sorts intelligently" do
    sql = User.select { |m| m.name == 'jon' }
    sql = sql.select { |m| m.age == 22 }
    sql = sql.sort_by { |m| m.name }
    sql = sql.select { |m| m.power == true }
    sql = sql.sort_by { |m| m.email }
    sql = sql.select { |m| m.admin == true && m.email == 'chris@ozmm.org' }
    sql.to_sql.should == "SELECT * FROM users WHERE users.`name` = 'jon' AND users.`age` = 22 AND users.`power` = 1 AND (users.`admin` = 1 AND users.`email` = 'chris@ozmm.org') ORDER BY users.name, users.email"
  end
end
