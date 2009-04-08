require File.join( File.dirname(__FILE__), "..", "spec_helper" )

include RepertoireCore

describe RepertoireCore::UserMailer do
  
  def deliver(action, mail_opts= {},opts = {})
    UserMailer.dispatch_and_deliver action, mail_opts, opts
    @delivery = Merb::Mailer.deliveries.last
  end
  
  before(:each) do
    @u = User.new(:email => "shakespeare@globe.com", :activation_code => "12345")
    @mailer_params = { :from      => "repertoire@mit.edu",
                       :to        => @u.email,
                       :subject   => "Welcome to MySite.com" }
  end
  
  after(:each) do
    Merb::Mailer.deliveries.clear
  end
  
  it "should send mail to shakespeare@globe.com for the signup email" do
    deliver(:signup, @mailer_params, :user => @u)
    @delivery.assigns(:headers).should include("to: shakespeare@globe.com")
  end
  
  it "should send the mail from 'repertoire@mit.edu' for the signup email" do
    deliver(:signup, @mailer_params, :user => @u)
    @delivery.assigns(:headers).should include("from: repertoire@mit.edu")
  end
  
  it "should mention the users login in the text signup mail" do
    deliver(:signup, @mailer_params, :user => @u)
    @delivery.text.should include(@u.full_name)
  end
  
  it "should mention the activation link in the signup emails" do
    the_url = UserMailer.new.url(:activate, :activation_code => @u.activation_code)
    the_url.should_not be_nil
    deliver(:signup, @mailer_params, :user => @u, :link => the_url)
    @delivery.text.should include( the_url )
  end
  
  it "should send mail to shakespeare@globe.com for the activation email" do
    deliver(:activation, @mailer_params, :user => @u)
    @delivery.assigns(:headers).should include("to: shakespeare@globe.com")
  end
  
  it "should send the mail from 'repertoire@mit.edu' for the activation email" do
    deliver(:activation, @mailer_params, :user => @u)
    @delivery.assigns(:headers).should include("from: repertoire@mit.edu")    
  end

end