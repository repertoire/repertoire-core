require File.dirname(__FILE__) + '/../spec_helper'

include RepertoireCore

describe "RepertoireCore::Users (controller)" do
  
  before :all do
    User.auto_migrate!
  end
  
  before :each do
    User.all.destroy!
  end
  
  it "should have SessionMixin mixed into the User Controller" do
    Merb::Controller.should include(::Merb::SessionMixin)    
  end
  
  it "should provide a current_user method" do
    Users.new({}).should respond_to(:current_user)
    Users.new({}).should respond_to(:current_user=)
  end

  it 'allows signup' do
    users = User.count
    controller = create_user
    controller.should redirect      
    User.count.should == (users + 1)
  end

  it 'requires password on signup' do
    lambda do
      controller = create_user(:password => nil)
      controller.assigns(:user).errors.on(:password).should_not be_nil
      controller.should respond_successfully
    end.should_not change(User, :count)
  end
     
  it 'requires password confirmation on signup' do
    lambda do
      controller = create_user(:password_confirmation => nil)
      controller.assigns(:user).errors.should_not be_empty
      controller.should respond_successfully
    end.should_not change(User, :count)
  end

  it 'requires email on signup' do
    lambda do
      controller = create_user(:email => nil)
      controller.assigns(:user).errors.on(:email).should_not be_nil
      controller.should respond_successfully
    end.should_not change(User, :count)
  end

  it "should have a route for user activation" do
    request_to("/repertoire_core/activate/1234") do |params|
      params[:controller].should == "Users"
      params[:action].should == "activate" 
      params[:activation_code].should == "1234"
    end
  end

  it 'activates user' do
    controller = create_user(:email => "bill@globe.com", :password => "tiger", :password_confirmation => "tiger")
    @user = controller.assigns(:user)
    User.authenticate('bill@globe.com', 'tiger').should be_nil
    controller = get "/repertoire_core/activate/#{@user.activation_code}" 
    User.authenticate('bill@globe.com', 'tiger').should_not be_nil
  end

  it "should not log the user in automatically on creation" do
    dispatch_to(Users, :create, :user => {:email => "bill@globe.com", :first_name => 'Bill', :last_name => 'Shakespeare',
                                          :password => "tiger", :password_confirmation => "tiger"}) do |c|
      u = mock("user")
      User.should_receive(:new).and_return(u)
      u.should_receive(:save).and_return(true)
      u.should_receive(:email).at_least(:once).and_return('bill@globe.com')
      u.should_receive(:activation_code).at_least(:once).and_return('12345')
      u.should_receive(:full_name).at_least(:once).and_return('Bill Shakespeare')
      u.should_receive(:reload).and_return(true)
      c.should_not_receive(:current_user=)
    end
  end

  protected 
  def create_user(options = {})
    post "/repertoire_core/users/", :user => valid_user_hash.merge(options)
  end

end