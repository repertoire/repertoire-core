require File.join( File.dirname(__FILE__), "..", "spec_helper" )

require 'set'

include RepertoireCore

describe "Repertoire roles" do
  
  before(:all) do
    User.auto_migrate!
    Membership.auto_migrate!
    Role.auto_migrate!
  end
  
  before(:each) do
    User.all.destroy!
    Membership.all.destroy!
    Role.all.destroy!
    
    admin =   Role.create(:name => 'admin').save!
    manager = Role.create(:name => 'manager', :parent => admin,   :granted_by => admin).save!
    member =  Role.create(:name => 'member',  :parent => manager, :granted_by => manager).save!
    guest =   Role.create(:name => 'guest',   :parent => member,  :granted_by => manager).save!
    
    @nicholas = User.new(valid_user_hash.update(:first_name => 'Nicholas', :email => 'nick@company.com'))
    @nicholas.grant(:admin, @nicholas)                   # self-granting god role
    
    @suzy = User.new(valid_user_hash.update(:first_name => 'Suzy', :email => 'suzy@othercompany.com'))
    @nicholas.grant(:member, @suzy)
    
    [ @nicholas, @suzy ].each { |o| o.reload }
  end
  
  it "should make a valid role" do
    gaffer = Role.create(:name => 'gaffer')
  end
  
  describe "role checking" do
  
    it "should allow users to easily check if they match a certain role" do
      @nicholas.has_role?(:admin).should be_true
    end
  
    it "should implement nesting roles" do
      admin = :admin.to_role
      admin.implies?(:member).should be_true
      member = :member.to_role
      member.implies?(:admin).should be_false
    end
    
    it "should allow role checking to use either symbol or object" do
      admin = :admin.to_role
      @nicholas.has_role?(:admin).should == @nicholas.has_role?(admin)
    end
    
    it "should treat users with nesting roles as members of nested role" do
      @nicholas.has_role?(:admin).should be_true
      @nicholas.has_role?(:member).should be_true
      
      @suzy.has_role?(:admin).should be_false
      @suzy.has_role?(:member).should be_true
    end
  
  end
  
  describe "granting and joining" do
  
    it "returns other roles that can be granted by this one" do
      admin, manager, member, guest = :admin.to_role, :manager.to_role, :member.to_role, :guest.to_role
      
      admin.expand_grants.all? { |r| [ manager, member, guest ].should be_include(r) }
      manager.expand_grants.all? { |r| [ member, guest ].should be_include(r) }
      member.expand_grants.should be_empty
      guest.expand_grants.should be_empty
    end
    
#    it "returns roles that can grant this one" do
#      admin, member, guest, peon = :admin.to_role, :member.to_role, :guest.to_role, :peon.to_role
#      
#      guest.granted_by.all? { |r| [ member, admin ].should be_include(r) }
#      peon.granted_by.all? { |r| [ member, admin ].should be_include(r) }
#      member.granted_by.all? { |r| [ admin ].should be_include(r) }
#      admin.granted_by.should be_empty
#    end
    
#    it "returns the user that should review requests" do
#      admin, member, guest = :admin.to_role, :member.to_role, :guest.to_role
#      
#      guest.reviewed_by.should == [member]
#      member.reviewed_by.should == [manager]
#      admin.reviewed_by.should be_empty
#    end
  
  end
    
end