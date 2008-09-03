require File.join( File.dirname(__FILE__), "..", "spec_helper" )

include RepertoireCore

describe "Repertoire users" do
  
  before(:all) do
    User.auto_migrate!
  end
  
  before(:each) do
    User.all.destroy!
    @hash = valid_user_hash
    @user = User.new(@hash)
  end
  
  it "should make a valid user" do
    user = User.new(valid_user_hash)
    user.save
    user.errors.should be_empty
  end
  
  describe "authentication" do
    
    it "should have an email field" do
      user = User.new
      user.should respond_to(:email)
      user.valid?
      user.errors.on(:email).should_not be_nil      
    end
  
    it "should authenticate a user using a class method" do
      hash = valid_user_hash
      user = User.new(hash)
      user.save
      user.should_not be_new_record
      user.activate
      User.authenticate(hash[:email], hash[:password]).should_not be_nil
    end
  
    it "should not authenticate a user using the wrong password" do
      user = User.new(valid_user_hash)  
      user.save

      user.activate
      User.authenticate(valid_user_hash[:email], "not_the_password").should be_nil
    end

    it "should not authenticate a user using the wrong email" do
      user = User.create(valid_user_hash)  

      user.activate
      User.authenticate("not_the_login@blah.com", valid_user_hash[:password]).should be_nil
    end
  
    it "should not authenticate a user that does not exist" do
      User.authenticate("i_dont_exist", "password").should be_nil
    end
  end
  
  
  describe "the password fields" do
    
    it "should respond to password" do
      @user.should respond_to(:password)    
    end

    it "should respond to password_confirmation" do
      @user.should respond_to(:password_confirmation)
    end

    it "should respond to crypted_password" do
      @user.should respond_to(:crypted_password)    
    end

    it "should require password if password is required" do
      user = User.new( valid_user_hash.without(:password) )
      user.stub!(:password_required?).and_return(true)
      user.valid?
      user.errors.on(:password).should_not be_nil
      user.errors.on(:password).should_not be_empty
    end

    it "should set the salt" do
      user = User.new(valid_user_hash)
      user.salt.should be_nil
      user.send(:encrypt_password)
      user.salt.should_not be_nil    
    end

    it "should require the password on create" do
      user = User.new(valid_user_hash.without(:password))
      user.save
      user.errors.on(:password).should_not be_nil
      user.errors.on(:password).should_not be_empty
    end      
    
    it "should require password_confirmation if the password_required?" do
      user = User.new(valid_user_hash.without(:password_confirmation))
      user.save
      (user.errors.on(:password) || user.errors.on(:password_confirmation)).should_not be_nil
    end

    it "should fail when password is outside 4 and 40 chars" do
      [3,41].each do |num|
        user = User.new(valid_user_hash.with(:password => ("a" * num)))
        user.valid?
        user.errors.on(:password).should_not be_nil
      end
    end

    it "should pass when password is within 4 and 40 chars" do
      [4,30,40].each do |num|
        user = User.new(valid_user_hash.with(:password => ("a" * num), :password_confirmation => ("a" * num)))
        user.valid?
        user.errors.on(:password).should be_nil
      end    
    end

    it "should autenticate against a password" do
      user = User.new(valid_user_hash)
      user.save    
      user.should be_authenticated(valid_user_hash[:password])
    end

    it "should not require a password when saving an existing user" do
      hash = valid_user_hash
      user = User.new(hash)
      user.save
      user.should_not be_a_new_record
      user = User.first(:email => hash[:email])
      user.password.should be_nil
      user.password_confirmation.should be_nil
      user.email = "some_different_email_to_allow_saving@foo.com"
      (user.save).should be_true
    end
    
  end
  
  describe "activation setup" do
  
    it "should have an activation_code as an attribute" do
      @user.attributes.keys.any?{|a| a.to_s == "activation_code"}.should_not be_nil
    end

    it "should create an activation code on create" do
      @user.activation_code.should be_nil    
      @user.save
      @user.activation_code.should_not be_nil
    end

    it "should not be active when created" do
      @user.should_not be_activated
      @user.save
      @user.should_not be_activated    
    end

    it "should respond to activate" do
      @user.should respond_to(:activate)    
    end
    
    it "should respond to activated?" do
      @user.save
      @user.should_not be_activated
      @user.activate
      @user.reload
      @user.should be_activated
    end

    it "should activate a user when activate is called" do
      @user.should_not be_activated
      @user.save
      @user.activate
      @user.should be_activated
      User.first(:email => @hash[:email]).should be_activated
    end

    it "should should show recently activated when the instance is activated" do
      @user.should_not be_recently_activated
      @user.activate
      @user.should be_recently_activated
    end

    it "should not show recently activated when the instance is fresh" do
      @user.activate
      @user = nil
      User.first(:email => @hash[:email]).should_not be_recently_activated
    end
    
    it "should check that a user is activated before authenticating" do
      hash = valid_user_hash
      
      user = User.new(hash)
      user.save
      user.reload
      User.authenticate(user.email, hash[:password]).should be_nil
      
      user.activate
      user.reload
      User.authenticate(user.email, hash[:password]).should == user
    end
    
    it "should not activate the user before activation link is clicked" do
      u = User.new(valid_user_hash)
      u.save
      u.should_not be_activated      
    end

  end
  
  describe "forgotten passwords" do
    
    before :each do
      @hash = valid_user_hash
      @user = User.new(@hash)
      @user.activate
      @user.save
      @user.reload
    end
    
    it "allow login after the forgotten password key is cleared" do
      @user.forgot_password!
      @user.clear_forgotten_password!
      @user.forgotten_password?.should == false
    end
  
    it "can be cleared by authenticating with the old password" do
      User.authenticate(@hash[:email], @hash[:password]).should == @user
      @user.forgotten_password?.should == false
    end
  
  end
  
end
