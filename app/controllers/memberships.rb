class RepertoireCore::Memberships < RepertoireCore::Application
  
  include Merb::MembershipsHelper
  include Merb::Helpers::DateAndTime
  
  before :ensure_authenticated
  
  # User membership history
  def index(shortname)
    @user                = User.first(:shortname => shortname)
    raise NotFound unless @user
    
    @history             = @user.history
    
    if (session.user == @user)
      @add_mode  = :subscribe
      @add_roles = session.user.subscribable_roles
    else
      @add_mode  = :grant
      @add_roles = session.user.grantable_roles - (@user.roles | @user.roles_pending_review)
    end
    
    display @history
  end

  # Start a subscription or grant process, depending on selected user vs. session user
  def new(shortname, role_name)
    only_provides :html
    @user        = User.first(:shortname => shortname)
    @role        = Role[role_name]
    raise NotFound unless @user
    
    @history     = @user.history(role_name)
    
    mode         = (session.user == @user) ? :subscribe : :grant
    
    render mode
  end

  # Workhorse of the membership controller: subscribe or grant a membership
  def create(shortname, role_name, note=nil)
    @user     = User.first(:shortname => shortname)
    raise NotFound unless @user    
        
    if @user == session.user
      notice = subscribe_and_notify(role_name, note)
    else
      notice = grant_and_notify(role_name, @user, note)
    end
    
    redirect slice_url(:repertoire_core, :user_memberships, @user.shortname), :message => { :notice => notice }
  end

  # Called to begin the review process
  def edit(id)
    only_provides :html
    @membership = Membership.get(id)
    raise NotFound unless @membership
    
    @user        = @membership.user
    @role_name   = @membership.role.name
    @history     = @user.history(@role_name) - [@membership]
    
    display @membership
  end

  # Called to complete the review process
  def update(id, membership, submit)
    @membership = Membership.get(id)
    raise NotFound unless @membership
    raise Forbidden unless !@membership.reviewed?
    
    approve       = (submit == 'approve')
    reviewer_note = membership[:reviewer_note]
      
    @membership = session.user.review(@membership, approve, reviewer_note)
    
    status        = (@membership.approved? ? :approve : :deny)
    deliver_email(status, @membership.user, {:subject => "Your request for Repertoire privileges"}, 
                                            {:membership => @membership,
                                             :link => absolute_slice_url(:repertoire_core, :user_memberships, session.user.shortname) })

    redirect slice_url(:repertoire_core, :requests, :shortname => session.user.shortname), 
                       :message => { :notice => 'Your review was recorded, and the user emailed' }
  end

  #
  # Utility functions
  #

  protected

  # subscribes current user to the given role, emailing reviewers if necessary. @returns feedback notice
  def subscribe_and_notify(role_name, note)
    membership = session.user.subscribe(role_name, note)
    
    if membership.approved?
      notice = "Your request approved automatically.  Welcome!"
    
    else
      reviewers = Role[role_name].grantors
      # TODO. might need to do this is a callback so it's asynchronous
      reviewers.each do |user|
        deliver_email(:request, user, {:subject => "Repertoire membership subscription to review"}, 
                                      {:membership => membership, 
                                       :reviewer => user,
                                       :link => absolute_slice_url(:repertoire_core, :edit_user_membership, membership.user.shortname, membership.id) })
      end                                     
      notice = "Reviewers have been notified of your subscription.  You will receive an email reply soon."
    end
    
    notice
  end
  
  # current user grants the given role; sends notice of new status. @returns feedback notice
  def grant_and_notify(role_name, user, note)
    membership = session.user.grant(role_name, user, note)
    deliver_email(:grant, user, {:subject => "You have been granted new Repertoire privileges"}, 
                                {:membership => membership,
                                 :link => absolute_slice_url(:repertoire_core, :edit_user_membership, membership.user.shortname, membership.id) })
    notice = "Grant completed.  The user has been emailed."
    notice
  end

  def deliver_email(action, to_user, params, send_params)
    from = Merb::Slices::config[:repertoire_core][:email_from]
    RepertoireCore::UserMailer.dispatch_and_deliver(action, params.merge(:from => from, :to => to_user.email), 
                                                    send_params)
  end
end # Memberships