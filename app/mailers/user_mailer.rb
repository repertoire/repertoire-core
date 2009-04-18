class RepertoireCore::UserMailer < Merb::MailController
  
  controller_for_slice RepertoireCore, :templates_for => :mailer, :path => "views"
  
  # User registration / passwords
  
  def signup 
    @user = params[:user]
    @link = params[:link]
    Merb.logger.info "Sending Signup to #{@user.email} with code #{@user.activation_code}"
    render_mail :text => :signup, :layout => :core
  end
  
  def activation
    @user = params[:user]
    @link = params[:link]
    Merb.logger.info "Sending Activation email to #{@user.email}"
    render_mail :text => :activation, :layout => :core
  end
  
  def password_reset_key
    @user = params[:user]
    @link = params[:link]
    Merb.logger.info "Sending Password Reset Key to #{@user.email} with code #{@user.password_reset_key}"
    render_mail :text => :password_reset_key, :layout => :core
  end    
  
  # Role membership
  
  def request
    @reviewer   = params[:reviewer]
    @membership = params[:membership]
    @link = params[:link]
    Merb.logger.info "Sending Role Request Review (#{@membership.role.name}) to #{@reviewer.email}"
    render_mail :text => :request, :layout => :core
  end
  
  def grant
    @membership = params[:membership]
    @link = params[:link]
    Merb.logger.info "Sending Role Grant (#{@membership.role.name})"
    render_mail :text => :grant, :layout => :core
  end
  
  def approve
    @membership = params[:membership]
    @link = params[:link]
    Merb.logger.info "Sending Role Approval (#{@membership.role.name}) to #{@membership.user.email}"
    render_mail :text => :approve, :layout => :core
  end
  
  def deny
    @membership = params[:membership]
    @link = params[:link]
    Merb.logger.info "Sending Role Denial (#{@membership.role.name}) to #{@membership.user.email}"
    render_mail :text => :deny, :layout => :core
  end
end
