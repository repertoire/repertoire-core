class RepertoireCore::Users < RepertoireCore::Application
    
  include Merb::MembershipsHelper  
    
  before :ensure_authenticated, :exclude => [:new, :validate_user, :create, :activate, :forgot_password, :password_reset_key, :reset_password ]
  
  log_params_filtered 'user[email]'
  
    #
    # Profile page.
    #
  
    # User profile display - defers to edit form
    def show(shortname)
      @user = User.first(:shortname => shortname)
      raise NotFound unless @user
      display @user, :edit
    end
  
    # Show user profile page
    def edit(shortname)
      only_provides :html
      @user = User.first(:shortname => shortname)
      raise NotFound unless @user
      display @user
    end
  
    # Updates user profile.  Not for password changes.
    def update(shortname, user)
      @user = User.first(:shortname => shortname)
      raise NotFound unless @user
      raise Unauthorized unless @user == session.user        # only self can update profile
    
      user[:password] = user[:password_confirmation] = nil   # close security hole by disallowing password changes
    
      if @user.update_attributes(user)
        redirect '/', :message => { :notice => "Updated your account." }
      else
        display @user, :edit
      end
    end
  
    #
    # Web services
    #
  
    # User validation web service for edit and signup forms
    def validate_user(user, id = nil)
      only_provides :json
    
      @user = id ? User.get(id) : User.new
      @user.attributes = user
    
      display @user.valid? || @user.errors_as_params
    end
    
    #
    # Registration.
    #
      
    # Displays the form for user signup
    def new(user = {})
      only_provides :html
      @user = User.new(user)
      display @user
    end

    # Registers a new user and delivers the authorization email
    # TODO.  should we accept registrations to the same email so long as the account is unactivated?
    def create(user)
      @user = User.new(user)
      # validate and email activation code
      if @user.save
        @user.reload
        deliver_email(:signup, @user, {:subject => "Please Activate Your Account"}, 
                                      {:user => @user,
                                       :link => absolute_url(:activate, :activation_code => @user.activation_code) }) 
        redirect '/', :message => { :notice => "Created your account.  Please check your email." }
      else
        message[:error] = "User could not be created"
        render :new
      end
    end
  
    # Activates a user from email after registration
    def activate(activation_code)
      session.abandon!
      @user = User.first(:activation_code => activation_code)
      raise NotFound unless session.user = @user
    
      if session.authenticated? && !session.user.activated?
        User.transaction do
          session.user.activate
          deliver_email(:activation, session.user, {:subject => "Welcome"},
                                                   {:user => session.user,
                                                    :link => absolute_url(:login, :email => session.user.email)})
        end
      end
    
      redirect '/', :message => { :notice => "Your account has been activated.  Welcome to Repertoire." }
    end
  
    #
    # Password management
    #

    # Display form for resetting a user password  
    def forgot_password
      only_provides :html    
      session.abandon!
    
      render
    end
  
    # Initiates a password change by emailing reset key to user's email
    def password_reset_key(email = nil)
      session.abandon!
      if @user = User.first(:email => email)    
        User.transaction do
          @user.forgot_password!
          deliver_email(:password_reset_key, @user, {:subject => "Request to change your password"}, 
                                                    {:user => @user,
                                                     :link => absolute_url(:reset_password, :key => @user.password_reset_key)})
        end
        redirect '/', :message => { :notice => "We've emailed a link to reset your password." }
      else
        message[:error] = "Unknown user email."
        render :forgot_password
      end
    end
  
    # Change password form: either for currently logged in user, or via password reset key
    # If password reset key is provided, has the side effect of temporarily logging in user
    def reset_password(key = nil)
      only_provides :html
      @user = session.user || User.first(:password_reset_key => key)
      raise NotFound unless @user

      session.user = @user
      display @user, :reset_password
    end  
  
    # Password change validation service
    # TODO.  like the signup/login forms, insecure unless processed via https. also open to brute-force attacks
    def validate_reset_password(user, current_password = nil)
      only_provides :json

      @user = session.user
      @user.attributes = user
      msgs = {}
    
      unless @user.password_reset_key || User.authenticate(@user.email, current_password)
        msgs = { :current_password => ['Incorrect current password'] }
      end

      display (@user.valid? && msgs.empty?) || msgs.merge(@user.errors_as_params)
    end
  
    # action to update a user's password.  only allowed if user signed in via a password reset key,
    # or can confirm their own credentials
    def update_password(user = {}, current_password = nil)
      @user = session.user
    
      # make sure user changing password knows existing one or logged in via a reset key
      raise Merb::ControllerExceptions::Forbidden unless @user.password_reset_key || User.authenticate(@user.email, current_password)

      @user.password              = user[:password]
      @user.password_confirmation = user[:password_confirmation]
  
      if @user.save
        @user.clear_forgotten_password!
        redirect '/', :message => { :notice => "Password Changed" }
      else
        message[:error] = "Password not changed: Please try again"
        render :reset_password
      end
    end
  
    #
    # Role membership
    #
  
    #
    # Pending role membership review
    #
    
    # TODO.  move this into separate controller, REST-style?
    def requests(shortname)
      @user                    = User.first(:shortname => shortname)
      @memberships             = @user.requests_to_review
      
      raise Unauthorized unless @user == session.user
      
      display @memberships
    end

    #
    # User search page
    #
      
    def index(name=nil)
      provides :html, :text
      @name = name
      @users = suggest_users(name)
      display @users
    end
    
    def complete_name(q)
      # jquery.suggest legislates the use of 'q' param
      @users = suggest_users(q)
      names  = @users.map { |u| "#{u.first_name} #{u.last_name}"}
      names.join("\n")                  # jquery.suggest requires text/plain, newline formatted
    end
  
    #
    # Utility functions
    #
  
    protected
    
    # Suggest possible users based on a prefix, which can match last, first, or shortname.
    # If no prefix provided, no search is made since there might be thousands of users
    #
    # On PostgreSQL, the match is case-insensitive
    def suggest_users(prefix, options ={})
      return [] if prefix.nil?

      # raise User.repository.adapter.options[:adapter].inspect
      
      query = case User.repository.adapter.options[:adapter]
        when 'postgres': "(first_name || ' ' || last_name) ILIKE ? OR shortname ILIKE ?"
        else             "(first_name || ' ' || last_name) LIKE ? OR shortname LIKE ?"
      end
      
      User.all({:conditions => [query, "%#{prefix}%", "#{prefix}%"],
                :order => [:last_name, :first_name]}.merge(options))
    end

    def deliver_email(action, to_user, params, send_params)
      from = Merb::Slices::config[:repertoire_core][:email_from]
      RepertoireCore::UserMailer.dispatch_and_deliver(action, params.merge(:from => from, :to => to_user.email), 
                                                      send_params)
    end
        
    # Remove password and password_confirmation from the server logs.
    #  TODO.  find more elegant way of doing this
    #         can be removed as soon as merb-param-protection allows for testing params like :user => [:password]
    #
    # CY 8/2009.  After Merb release 1.0.10, it appears even this approach to filtering passwords from server logs
    #             doesn't work (param processing flow has changed so both this and merb-param-protection now
    #             to clobber the real password and password_confirmation params)
    #
    # This issue is documented at https://merb.lighthouseapp.com/projects/7433/tickets/1046-password-filtering-bug
    #
    #def self._filter_params(params)
    #  result = params.dup
    #  result[:current_password] =             '[FILTERED]' if result[:current_password]
    #  result[:user][:password] =              '[FILTERED]' if result[:user] && result[:user][:password]
    #  result[:user][:password_confirmation] = '[FILTERED]' if result[:user] && result[:user][:password_confirmation]
    #  result
    #end

  end
