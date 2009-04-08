class RepertoireCore::Users < RepertoireCore::Application
  
  # alter this stub to configure redirects and response messages for the repertoire core
  # user registration and admin functions in your application.  the actions you may want to
  # redirect after are: create, update, activate, password_reset_key, reset_password
  
  # with the exception of activate (below), these actions default to redirect to the application root, '/'
  # if this suffices, no need to reconfigure here
  
  after :redirect_after_activate,  :only => :activate, :if => lambda{ !(300..399).include?(status) }
  
  private   
  # @overwritable
  def redirect_after_activate
    message[:notice] = "Your account has been activated.  Please update your personal information."
    redirect resource(session.user), :message => message
  end
  
end