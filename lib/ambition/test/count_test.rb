require File.dirname(__FILE__) + '/helper'

context "Count" do
  setup do
    hash = { :conditions => "users.`name` = 'jon'" }
    User.expects(:count).with(hash)
    @sql = User.select { |m| m.name == 'jon' }
  end

  specify "size" do
    @sql.size
  end

  specify "length" do
    @sql.length
  end
end
