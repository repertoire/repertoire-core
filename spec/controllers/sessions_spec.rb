require File.dirname(__FILE__) + '/../spec_helper'

include RepertoireCore

describe "RepertoireCore::Users (controller)" do
  
  before :all do
    User.auto_migrate!
  end
  
  before :each do
    User.all.destroy!
    u = User.new
    u.valid?
    @quentin = User.create(valid_user_hash.with(:email => "bill@globe.com", :password => "tiger", :password_confirmation => "tiger"))
    @controller = Sessions.new(fake_request)
    @quentin.activate
  end
  
  it "should have a route to Sessions#new from '/login'" do
    request_to("/repertoire_core/login") do |params|
      params[:controller].should == "Sessions"
      params[:action].should == "create"
    end   
  end

  it "should route to Sessions#create from '/login' via post" do
    request_to("/repertoire_core/login", :post) do |params|
      params[:controller].should  == "Sessions"
      params[:action].should      == "create"
    end      
  end
  
  it "should have a named route :login" do
    @controller.url(:login).should == "/login"
  end
  
  it "should have route to Sessions#destroy from '/logout' via delete" do
    request_to("/logout", :delete) do |params|
      params[:controller].should == "Sessions"
      params[:action].should    == "destroy"
    end   
  end
  
  it "should route to Sessions#destroy from '/logout' via get" do
    request_to("/logout") do |params|
      params[:controller].should == "Sessions" 
      params[:action].should     == "destroy"
    end
  end

  it 'logins and redirects' do
    controller = post "/login", :email => 'bill@globe.com', :password => 'tiger'
    controller.session[:user].should_not be_nil
    controller.session[:user].should == @quentin.id
    # controller.should redirect_to("/")
  end
   
  it 'fails login and does not redirect' do
    controller = post "/login", :email => 'bill@globe.com', :password => 'bad password'
    controller.session[:user].should be_nil
    controller.should be_successful
  end

  it 'logs out' do
    controller = get("/logout"){|controller| controller.stub!(:current_user).and_return(@quentin) }
    controller.session[:user].should be_nil
    controller.should redirect
  end

  it 'remembers me' do
    controller = post "/login", :email => 'bill@globe.com', :password => 'tiger', :remember_me => "1"
    controller.cookies["auth_token"].should_not be_nil
  end
 
  it 'does not remember me' do
    controller = post "/login", :email => 'bill@globe.com', :password => 'tiger', :remember_me => "0"
    controller.cookies["auth_token"].should be_nil
  end
  
  it 'deletes token on logout' do
    controller = get("/logout") {|request| request.stub!(:current_user).and_return(@quentin) }
    controller.cookies["auth_token"].should == nil
  end
  
  it 'logs in with cookie' do
    @quentin.remember_me
    controller = get "/login" do |c|
      c.request.env[Merb::Const::HTTP_COOKIE] = "auth_token=#{@quentin.remember_token}"
    end
    controller.should be_authenticated
  end

  def auth_token(token)
    CGI::Cookie.new('name' => 'auth_token', 'value' => token)
  end
    
  def cookie_for(user)
    auth_token user.remember_token
  end
end