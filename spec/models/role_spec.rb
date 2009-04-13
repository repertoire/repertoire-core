require File.join( File.dirname(__FILE__), "..", "spec_helper" )

include RepertoireCore

describe Role do
  
  before(:each) do
    User.auto_migrate!
    Membership.auto_migrate!
    Role.auto_migrate!
  end
  
  describe "declarations" do
  
    it "should create new roles when given with a title" do
      Role.declare do
        Role[:admin, "The system administrator"]
      end
      Role.all.size.should == 1
    end

    it "should allow access to roles outside declarations" do
      Role.declare do
        Role[:admin]
      end
      Role[:admin].should == Role.first(:name => 'admin')
    end

    it "should disallow creating roles outside declarations" do
      lambda { Role[:admin] }.should raise_error
    end
  
    it "should create new roles as they are mentioned subsequently" do
      Role.declare do
        Role[:admin].implies(:member)
      end
      Role.all.size.should == 2
    end
  
    it "should chain the state of roles as they are declared" do
      Role.declare do
        Role[:admin].implies(:manager).implies(:member)
      end
      Role[:admin].parent.should be_nil
      Role[:manager].parent.should == Role[:admin]
      Role[:member].parent.should == Role[:manager]
    end 
  
    it "should set parentage according to grants by default" do
      Role.declare do
        Role[:admin].grants(:manager).grants(:member)
      end
    
      Role[:admin].granted_by.should   be_nil
      Role[:manager].granted_by.should == Role[:admin]
      Role[:member].granted_by.should  == Role[:manager]
    
      Role[:admin].parent.should   be_nil
      Role[:manager].parent.should == Role[:admin]
      Role[:member].parent.should  == Role[:manager]
    end
  
    it "should allow grants to differ from parents" do
      Role.declare do
        Role[:admin].implies(:manager).implies(:member)
        Role[:admin].grants(:manager, :member)
      end
    
      Role[:admin].parent.should   be_nil
      Role[:manager].parent.should == Role[:admin]
      Role[:member].parent.should  == Role[:manager]
    
      Role[:manager].granted_by.should == Role[:admin]
      Role[:member].granted_by.should  == Role[:admin]
    end
  
    it "should permit opening and closing role" do
      Role.declare do
        Role[:admin].grants(:manager).open
        Role[:guest].open
      end
    
      Role[:admin].should       be_closed_membership
      Role[:manager].should_not be_closed_membership
      Role[:manager].should_not be_open_membership
      Role[:guest].should       be_open_membership 
    end
  
  end  
  
  describe "membership checking logic" do
  
    before(:each) do
      Role.declare do
        Role[:admin].grants(:manager).grants(:member).grants(:guest)
      end
    
      @suzy, @nick = (1..2).map { User.create(valid_user_hash) }
      Role.grant!(:admin, @nick)
      Role.grant!(:member, @suzy)
    end
    
    it "should complain when accessing a non-existent role outside a declaration" do
      lambda { Role[:foobar] }.should raise_error
    end
  
    it "should allow users to easily check if they match a certain role" do
      @nick.has_role?(:admin).should be_true
    end
  
    it "should implement hierarchical roles" do      
      Role[:admin].implies?(:member).should be_true
      Role[:member].implies?(:admin).should be_false
    end
    
    it "should allow role checking to use either symbol or object" do    
      @nick.has_role?(:admin).should == @nick.has_role?(Role[:admin])
    end
    
    it "should treat users with nesting roles hierarchically" do      
      @nick.has_role?(:admin).should  be_true
      @nick.has_role?(:member).should be_true
      
      @suzy.has_role?(:admin).should  be_false
      @suzy.has_role?(:member).should be_true
    end
    
    it "should provide complete lists of all a user's roles" do
      @nick.expanded_roles.size.should == 4
      (@nick.expanded_roles - [ Role[:admin], Role[:manager], Role[:member], Role[:guest] ]).should be_empty
      
      @suzy.expanded_roles.size.should == 2
      (@suzy.expanded_roles - [ Role[:member], Role[:guest] ]).should be_empty
    end
      
  end
    
  describe "granting logic" do
  
    it "should automatically grant memberships issued by super-user" do      
      Role.declare do
        Role[:admin]
      end
      
      nicholas = User.create(valid_user_hash)
      Role.grant!(:admin, nicholas)
      nicholas.has_role?(:admin).should be_true
    end

    it "should allow roles to access granted_by and grants directly" do
      Role.declare do
        Role[:secretary].grants(:janitor)
      end

      Role[:secretary].grants.should   include(Role[:janitor])
      Role[:janitor].granted_by.should == Role[:secretary]    
    end

    it "should require all user level grants be authorized" do     
      Role.declare do
        Role[:admin].grants(:lackey)
      end
      nicholas = User.create(valid_user_hash)
      Role.grant!(:lackey, nicholas)

      # nicholas attempts to grant himself a closed role
      lambda { nicholas.grant(:admin, nicholas) }.should raise_error
    end

    it "should allow users specified in a role's granted_by relation to grant it without review" do
      Role.declare do
        Role[:secretary].grants(:janitor)
      end  
      jack, tim, joe = (1..3).map { User.create(valid_user_hash) }
      Role.grant!(:secretary, jack)
    
      # secretaries can appoint janitors, so no error
      jack.grant(:janitor, tim)
      tim.has_role?(:janitor).should be_true

      # having a role doesn't mean you can also grant it:  janitors can't appoint other janitors
      lambda { tim.grant(:janitor, joe) }.should raise_error
    end

    it "should allow users with access to a granting role by implication to grant it" do      
      Role.declare do
        Role[:president].implies(:secretary).implies(:janitor)
        Role[:secretary].grants(:janitor)
      end
      nick, jack = (1..2).map { User.create(valid_user_hash) }
      Role.grant!(:president, nick)

      # grant role by proxy: president can act as secretary, and secretary can grant janitor
      nick.grant(:janitor, jack)
      jack.has_role?(:janitor).should be_true
    end
    
    it "failed grants should leave no record in the memberships table" do  
      Role.declare do
        Role[:president].implies(:janitor)
      end
      nick, jack = (1..2).map { User.create(valid_user_hash) }
      Role.grant!(:janitor, nick)

      lambda { nick.grant(:president, jack) }.should raise_error
      Membership.all.size.should == 1
    end
    
    it "grants, subscriptions and reviews should return the relevant membership" do
      Role.declare do
        Role[:president].grants(:secretary)
        Role[:secretary].grants(:janitor)
      end
      nick, jack, suzy = (1..3).map { User.create(valid_user_hash) }

      Role.grant!(:president, nick).should be_approved
      nick.grant(:secretary, jack).should be_approved
      (request = suzy.subscribe(:janitor)).should_not be_reviewed
      jack.review(request, true).should be_approved
    end
  end

  describe "granting inference rules" do      

    before(:each) do
      Role.declare do
        Role[:admin].grants(:gaffer, :lackey)
        Role[:lackey].grants(:chav)
      end
    
      @tim, @john = (1..2).map { User.create(valid_user_hash) }
      Role.grant!(:admin,  @tim)
      Role.grant!(:lackey, @john)
    end

    it "should accurately list direct grantable roles" do
      (@tim.grantable_roles  - [Role[:lackey], Role[:gaffer]]).should be_empty
      (@john.grantable_roles - [ Role[:chav] ]).should                be_empty
    end
  
    it "should detect directly grantable roles" do
      @tim.can_grant?(:lackey, :gaffer).should be_true
      @john.can_grant?(:chav).should           be_true
    end
  
    it "should detect roles grantable through a role the user holds" do
      @tim.can_grant?(:chav).should be_true
    end
  
    it "shouln't allow users to grant roles other than these" do
      @john.can_grant?(:lackey).should be_false
      @john.can_grant?(:gaffer).should be_false
      @john.can_grant?(:admin).should be_false
      @tim.can_grant?(:admin).should be_false
    end
  end

  
  describe "subscription logic" do      

    it "subscriptions to roles with open membership approve automatically" do
      Role.declare do
        Role[:toastmasters].open
      end
      nick = User.create(valid_user_hash)
      nick.subscribe(:toastmasters)
      
      # membership for open roles succeeds immediately
      nick.has_role?(:toastmasters).should be_true
    end
    
  end
    
  describe "review process" do      
    
    before :each do
      Role.declare do
        Role[:yacht_club_secretary].grants(:yacht_club_member)
      end
      @suzy, @nick = (1..2).map { User.create(valid_user_hash) }
      Role.grant!(:yacht_club_secretary, @suzy)
    end
  
    it "review process should allow users to subscribe for roles; membership requests are reviewed later" do
      yacht_club_request = @nick.subscribe(:yacht_club_member)
      @nick.has_role?(:yacht_club_member).should be_false
      
      # at a later date suzy reviews nick's membership request
      @suzy.review(yacht_club_request, true, "Paid his $10000 annual fee")
      @nick.has_role?(:yacht_club_member).should be_true
    end
  
    it "unapproved or denied role memberships should not be available to users" do
      yacht_club_request = @nick.subscribe(:yacht_club_member)
      @nick.has_role?(:yacht_club_member).should be_false
      
      # at a later date suzy denies nick's membership request
      @suzy.review(yacht_club_request, false, "Killed the watchdog last night")
      @nick.has_role?(:yacht_club_member).should be_false
    end
    
  end
  
end