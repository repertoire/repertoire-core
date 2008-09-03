class RepertoireCore::Users < RepertoireCore::Application
  
  include RepertoireCore::WhoisHelper

  before :authenticate, :exclude => [ :new, :create, :activate, :forgot_password, :reset_password ]
  # before :authorize, :with => :list_users, :only => :index
  before :check_logged_out, :only => [ :new, :create, :activate, :forgot_password ]
  
  only_provides :html
  
  # Lists users
  def index
    @requests_count = Membership.count(:reviewer_id => nil)
    @users = User.all(:order => [:email])
    render
  end
  
  #
  # Profile page
  #
  
  # Show user profile page
  def edit
    @user = User.get!(params[:id])
    
    display @user
  end
  
  # Updates user profile
  def update
    @user = User.get!(params[:id])
    
    if @user.update_attributes(params[:user])
      redirect '/', :message => "Updated your account."
    else
      render :edit
    end
  end
  
  #
  # Registration
  #
      
  # Displays the new form signup
  def new
    @user = User.new(params[:user] || {})
    display @user
  end

  # Registers a new user and delivers the authorization email
  def create
    cookies.delete :auth_token

    @user = User.new(params[:user])
    if @user.save
      @user.reload
      deliver_email(:signup, @user, {:subject => "Please Activate Your Account"}, 
                                    {:user => @user,
                                     :link => absolute_url(:user_activation, :activation_code => @user.activation_code) })
      redirect '/', :message => "Created your account.  Please check your email to complete the registration process."
    else
      render :new
    end
  end
  
  # Activates a user from email after registration
  def activate
    self.current_user = User.first(:activation_code => params[:activation_code])
    # TODO.  we require user to activate immediately after signup (authenticated?)  too restrictive?
    if authenticated? && !current_user.activated?
      Merb.logger.info "Activated #{current_user}"
      msg = "Your account has been activated.  Welcome to Repertoire."
      current_user.activate
      update_institution!(current_user)
      deliver_email(:activation, current_user, {:subject => "Welcome"},
                                               {:user => current_user,
                                                :link => absolute_url(:login, :email => current_user.email)})
    else
      msg = "Unknown activation code.  Please try again."
    end
    redirect '/', :message => msg
  end
  
  #
  # Password management
  #
  
  # Initiates a password reset by prompting for email
  def forgot_password
    @email = params[:email]
    @user = User.first(:email => @email)
    unless @user.nil?
      raise Unauthorized if authenticated? && @user != current_user
      @user.forgot_password!
      deliver_email(:forgot_password, @user, {:subject => "Request to change your password"}, 
                                             {:user => @user,
                                              :link => absolute_url(:reset_password, :key => @user.password_reset_key)})
      redirect "/", :message => "We've emailed you a link to reset your password."
    else
      @notice = "Could not find your email.  Please try again." unless @email.nil?
      render
    end
  end
  
  # reset_password is the link given in the email
  def reset_password
    @user = User.first(:password_reset_key => params[:key]) || current_user
    if @user.nil?
      redirect "/", :message => "Unknown password reset code."
    else
      self.current_user = @user
      render
    end
  end
  
  # action to change password on reset
  def update_password  
    @user = current_user
    if params[:user][:password].nil?
      return redirect(url(:reset_password, :key => @user.password_reset_key), :message => "You must enter a password")
    end
    
    # if current user changing password, make sure they know existing one
    unless @user.password_reset_key || User.authenticate(@user.email, params[:current_password])
      return redirect(url(:reset_password, :key => @user.password_reset_key), :message => "Incorrect current password")
    end

    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
  
    if @user.save
      @user.clear_forgotten_password!
      redirect "/", :message => "Password Changed"
    else
      redirect url(:reset_password, :key => @user.password_reset_key), :message => "Password not changed: Please try again"
    end     
  end
  
  #
  # Role membership
  #
  
  # not used yet
  def subscribe
    raise NotImplementedError, "role subscription implementation delayed until we have a proper project-listing UI"
    # deliver_email(:request, role.reviewer, {:subject => "Repertoire role request"}, {:membership => @membership}
  end
  
  # show requests which current user is authorized to review
  def requests
    # TODO.  add full text search
    # TODO.  add pagination
    # TODO.  allow limiting by current project?
    # TODO.  limit by parent so we only get direct to review
    @users_count = User.count
    @requests = Membership.all(:order => [:updated_at.desc], :reviewer_id => nil)
    render
  end
  
  # show roles the current user is authorized to grant
  def grant
    # TODO.  authorization filter that makes sure current user has grant[zzz] permissions
    
    @role = Role.get(params[:role_id])
    @user = User.get(params[:user_id])
    @note = params[:note]
    
    if @role && @user
      current_user.grant(@role, @user, @note)                            # Exceptions render via merb system
      render "Granted #{@role.title} to #{@user.full_name}", :layout => false
    else
      @roles = current_user.grantable_roles.sort
      render :grant
    end
  end
  
  def review
    #deliver_email(:response, role.reviewer, {:subject => "Your request has been reviewed"}, {:user => current_user}) )
  end
  
  protected

  def deliver_email(action, to_user, params, send_params)
    from = Merb::Slices::config[:repertoire_core][:email_from]
    RepertoireCore::UserMailer.dispatch_and_deliver(action, params.merge(:from => from, :to => to_user.email), 
                                                    send_params)
  end
  
  private
  
  def check_logged_out
    throw :halt, 'Please log out first' if current_user
  end
  
  def update_institution!(user)
    begin
      props = lookup_domain(user.email)
      user.institution = props['OrgName']
      user.save!
    rescue WhoisException => e
      Merb.logger.warn(e)
    end
  end
  
end