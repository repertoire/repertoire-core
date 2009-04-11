require File.join( File.dirname(__FILE__), "..", "spec_helper" )

include RepertoireCore

describe RepertoireCore::Users do

  # TODO.  for unclear reasons, slice_url fails (merb 1.0.11) when called within test harness
  #        so tests below fail
  
  before :each do
    User.auto_migrate!
  end

  it 'allows signup' do
    users = User.all.size
    response = create_user
    response.should redirect      
    User.all.size.should == (users + 1)
  end

  it 'requires password on signup' do
    pending "MerbSlices fixes to slice_url"
    users = User.all.size
    response = create_user(:password => nil)
    response.should be_successful
    User.all.size.should == users  # i.e. no new user
  end
     
  it 'requires password confirmation on signup' do
    pending "MerbSlices fixes to slice_url"
    users = User.all.size
    response = create_user(:password_confirmation => nil)
    response.should be_successful
    User.all.size.should == users  # i.e. no new user
  end

  it 'requires email on signup' do
    pending "MerbSlices fixes to slice_url"
    users = User.all.size
    response = create_user(:email => nil)
    response.should be_successful
    User.all.size.should == users  # i.e. no new user
  end

  it "should have a route for user activation" do
    request_to("/activate/1234") do |params|
      params[:controller].should == "Users"
      params[:action].should == "activate" 
      params[:activation_code].should == "1234"
    end
  end

  it 'activates user' do
    pending "MerbSlices fixes to slice_url"
    response = create_user(:email => "bill@globe.com", :password => "tiger", :password_confirmation => "tiger")
    response.should redirect
    @user = User.first(:email => "bill@globe.com")
    @user.should_not be_nil
    
    #response = request url(:login), :method => "PUT", :params => { :email => "bill@globe.com", :password => "tiger" }
    #response.should_not redirect # i.e. should fail login
    
    response = request("/activate/#{@user.activation_code}")
    response.should redirect
    
    response = request url(:login), :method => "PUT", :params => { :email => "bill@globe.com", :password => "tiger" }
    response.should redirect # i.e. should succeed
  end

  protected 
  def create_user(options = {})
    request(resource(:users), :method => "POST", :params => { :user => valid_user_hash.merge(options) })
  end

end