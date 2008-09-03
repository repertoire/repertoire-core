class RepertoireCore::Sessions < RepertoireCore::Application
 
  before :authenticate, :exclude => [ :create ]

  def create
    @email, remember_me = params[:email], params[:remember_me]
    @notice = message
    self.current_user = User.authenticate(@email, params[:password])
    if authenticated?
      @notice = "Login successful"
      if remember_me == "1"
        self.current_user.remember_me
        expires = Time.parse(self.current_user.remember_token_expires_at.to_s)
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => expires }
        @notice += " - you will remain signed in until #{ format_date expires })"
      end
      redirect_back_or_default '/', :message => @notice
    else
      if @notice.blank? && params[:password]
        @notice = "Unknown email or password"
      end
      render :new
    end
  end

  def destroy
    self.current_user.forget_me if authenticated?
    cookies.delete :auth_token
    session.delete
    redirect_back_or_default '/', :message => "You have been logged out"
  end
end