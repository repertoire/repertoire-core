require File.join( File.dirname(__FILE__), "..", "spec_helper" )

require 'set'

include RepertoireCore

describe "Repertoire roles" do
  
  before(:each) do
    User.all.destroy!
    Membership.all.destroy!
    Role.all.destroy!
  end
  
  describe "creation and granting"
  
  it "should make a valid role" do
    Role.create(:name => :gaffer)
  end
  
  it "should automatically grant the first membership of any sort" do
    Role.create(:name => :admin, :granted_by => nil)
    nicholas = User.create(valid_user_hash)
    nicholas.grant(:admin, nicholas)
  end
  
  it "should require all subsequent roles to be granted by a specific user" do
    admin =  Role.create(:name => :admin,  :granted_by => nil)
    lackey = Role.create(:name => :lackey, :granted_by => nil)
    nicholas = User.create(valid_user_hash)
    
    # first role membership in system comes for free
    nicholas.grant(:admin, nicholas)
    
    # thereafter only users can grant other users roles
    lambda { nicholas.grant(:lackey, nicholas) }.should raise_error
  end

  it "should allow users specified in a role's granted_by relation to grant it" do
    secretary = Role.create(:name => :secretary, :granted_by => nil)
    janitor   = Role.create(:name => :janitor,   :granted_by => secretary)
    
    jack, tim, joe = (1..3).map { User.create(valid_user_hash) }
    jack.grant(:secretary, jack)
    
    # secretaries can appoint janitors
    jack.grant(:janitor, tim)

    # having a role doesn't mean you can grant it:  janitors can't appoint other janitors
    lambda { tim.grant(:janitor, joe) }.should raise_error
  end

  it "should allow users who inherit access to a granting role to grant by proxy" do
    president = Role.create(:name => :president, :granted_by => nil)
    secretary = Role.create(:name => :secretary, :granted_by => nil,       :parent => president)
    janitor   = Role.create(:name => :janitor,   :granted_by => secretary, :parent => president)

    nick, jack = (1..2).map { User.create(valid_user_hash) }
    nick.grant(:president, nick)

    # grant role by proxy: president can act as secretary, and secretary can grant janitor
    nick.grant(:janitor, jack)
  end
  
  describe "role checking" do
  
    before(:each) do
      admin =   Role.create(:name => 'admin')
      manager = Role.create(:name => 'manager', :parent => admin,   :granted_by => admin)
      member =  Role.create(:name => 'member',  :parent => manager, :granted_by => manager)
      guest =   Role.create(:name => 'guest',   :parent => member,  :granted_by => manager)
    
      #@nicholas = User.create(valid_user_hash.update(:first_name => 'Nicholas', :email => 'nick@company.com'))
      #@nicholas.grant(:admin, @nicholas)                   # self-granting god role
    
      #@suzy = User.create(valid_user_hash.update(:first_name => 'Suzy', :email => 'suzy@othercompany.com'))
      #@nicholas.grant(:member, @suzy)
    
      #[ @nicholas, @suzy ].each { |o| o.reload }
    end
  
    it "should allow users to easily check if they match a certain role" do
      pending
      @nicholas.has_role?(:admin).should be_true
    end
  
    it "should implement nesting roles" do
      pending
      admin = :admin.to_role
      admin.implies?(:member).should be_true
      member = :member.to_role
      member.implies?(:admin).should be_false
    end
    
    it "should allow role checking to use either symbol or object" do
      pending
      admin = :admin.to_role
      @nicholas.has_role?(:admin).should == @nicholas.has_role?(admin)
    end
    
    it "should treat users with nesting roles as members of nested role" do
      pending
      @nicholas.has_role?(:admin).should be_true
      @nicholas.has_role?(:member).should be_true
      
      @suzy.has_role?(:admin).should be_false
      @suzy.has_role?(:member).should be_true
    end
  
  end
  
  describe "granting and joining" do
  
    it "returns other roles that can be granted by this one" do
      pending
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