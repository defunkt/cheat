require File.dirname(__FILE__) + '/helper'

context "Joins" do
  specify "simple == on an association" do
    sql = User.select { |m| m.account.email == 'chris@ozmm.org' }
    sql.to_hash.should ==  { 
      :conditions => "accounts.email = 'chris@ozmm.org'", 
      :includes => [:account] 
    }
  end

  specify "simple mixed == on an association" do
    sql = User.select { |m| m.name == 'chris' && m.account.email == 'chris@ozmm.org' }
    sql.to_hash.should ==  { 
      :conditions => "(users.`name` = 'chris' AND accounts.email = 'chris@ozmm.org')", 
      :includes => [:account] 
    }
  end

  specify "multiple associations" do
    sql = User.select { |m| m.ideas.title == 'New Freezer' || m.invites.email == 'pj@hyett.com' }
    sql.to_hash.should ==  { 
      :conditions => "(ideas.title = 'New Freezer' OR invites.email = 'pj@hyett.com')",
      :includes => [:ideas, :invites]
    }
  end

  specify "non-existant associations" do
    sql = User.select { |m| m.liquor.brand == 'Jack' }
    should.raise { sql.to_hash } 
  end
end
