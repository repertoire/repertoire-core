class RepertoireCore::UserMailer < Merb::MailController
  
  controller_for_slice RepertoireCore, :templates_for => :mailer, :path => "views"
  
  # User registration / passwords
  
  def signup
    @user = params[:user]
    @link = params[:link]
    Merb.logger.info "Sending Signup to #{@user.email} with code #{@user.activation_code}"
    render_mail :text => :signup, :layout => nil
  end
  
  def activation
    @user = params[:user]
    @link = params[:link]
    Merb.logger.info "Sending Activation email to #{@user.email}"
    render_mail :text => :activation, :layout => nil
  end
  
  def forgot_password
    @user = params[:user]
    @link = params[:link]
    Merb.logger.info "Sending Forgot Password to #{@user.email} with code #{@user.password_reset_key}"
    render_mail :text => :forgot_password, :layout => nil
  end    
  
  # Role membership
  
  def request
    @membership = params[:membership]
    Merb.logger.info "Sending Role Request Review (#{@membership.role.name})"
    render_mail :text => :request, :layout => nil
  end
  
  def response
    @membership = params[:membership]
    Merb.logger.info "Sending Role Review Response (#{@membership.role.name}, #{@membership.approved? ? 'approved' : 'denied' }) to #{params[:to]}"
    render_mail :text => :approve, :layout => nil
  end
end
