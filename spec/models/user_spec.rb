require File.join( File.dirname(__FILE__), "..", "spec_helper" )

include RepertoireCore

describe User do
  
  WHOIS_MOCK_RESULT = <<-RESULT
        OrgName:    Massachusetts Institute of Technology 
        OrgID:      MIT-2
      RESULT
  
  before(:all) do
    whois_mock = mock("whois").should_receive(:search_whois).any_number_of_times.and_return(WHOIS_MOCK_RESULT)
    Whois::Whois.should_receive(:initialize).any_number_of_times.and_return(whois_mock)
  end
  
  before(:each) do
    User.auto_migrate!
    @hash = valid_user_hash
    @user = User.new(@hash)
    
    @request  = fake_request
    @params   = @request.params
    @auth     = Merb::Authentication.new(@request.session)
    
    @params[:email]    = @user.email
    @params[:password] = @user.password
  end
  
  it "should make a valid user" do
    user = User.new(valid_user_hash)
    user.save
    user.errors.should be_empty
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

    it "should not be activated when created" do
      @user.should_not be_activated
      @user.save
      @user.should_not be_activated    
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

    it "should not activate the user before activation link is clicked" do
      u = User.new(valid_user_hash)
      u.save
      u.should_not be_activated      
    end
    
    it "should allow activated users to log in" do
      @user.save
      @user.activate
      lambda { @request.session.authenticate!(@request, @params) }.should_not raise_error
    end
    
    it "should not allow unactivated users to log in" do
      @user.save
      lambda { @request.session.authenticate!(@request, @params) }.should raise_error
    end

  end
  
  describe "institution identification" do
    
    before :each do
      @hash = valid_user_hash
      @user = User.new(@hash)
    end
    
    it "should use whois service to lookup institutional affiliation after activation" do
      @user.save
      @user.activate
      @user.reload
      @user.institution_code.should == "MIT-2"
      @user.institution.should      == "Massachusetts Institute of Technology"
    end
    
    it "should wait until activation to lookup institution" do
      @user.save
      @user.reload
      @user.institution_code.should == nil
      @user.institution.should      == nil
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
      @user.forgotten_password?.should be_false
    end
  
    it "can be cleared by authenticating with the old password" do
      User.authenticate(@hash[:email], @hash[:password]).should == @user
      @user.forgotten_password?.should be_false
    end
  
  end
  
end
