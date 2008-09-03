module Merb
  class Controller
    
      include Merb::ControllerExceptions
    
      protected
        # Returns true or false if the user is logged in.
        # Preloads @current_user with the user model if they're logged in.
        def authenticated?
          !!current_user
        end
    
        # Accesses the current user from the session.  Set it to :false if login fails
        # so that future calls do not hit the database.
        def current_user
          @current_user ||= (login_from_session || login_from_basic_auth || login_from_cookie || false)
        end
    
        # Store the given user in the session.
        def current_user=(new_user)
          session[:user] = (!new_user || !new_user.kind_of?(User)) ? nil : new_user.id
          @current_user = new_user
        end

        # Filter method to enforce a login requirement.
        #
        # To require logins for all actions, use this in your controllers:
        #
        #   before :authenticate
        #
        # To require logins for specific actions, use this in your controllers:
        #
        #   before :authenticate, :only => [ :edit, :update ]
        #
        # To skip this in a subclassed controller:
        #
        #   skip_before :authenticate
        #
        def authenticate
          authenticated? || throw(:halt, :unauthorized)
        end
        
       # Redirect as appropriate when an access request fails.
       #
       # The default action is to redirect to the login screen.
       #
       # TODO.  this should hook in to merb's exceptions controller better.
       #        do we even need a separate method?
       #
       # Override this method in your controllers if you want to have special
       # behavior in case the user is not authorized
       # to access the requested action.  For example, a popup window might
       # simply close itself.
       def unauthorized
         case content_type
         when :html
           store_location
           redirect url(:login), :message => message
         when :xml
           basic_authentication.request
         end
       end 

        # Filter method to enforce a permission requirement.  Implies authenticate
        #
        # You can check for a specific permission by sending the permission symbol in your controllers:
        #
        #   before :authorize, :with => :deactivate_accounts, :only => :delete
        #
        # To require generic permissions of the form {controller_name}_{action_name}, use this:
        #
        #   before :authorize, :exclude => [ :some, :other, :actions ]
        #
        # For more complex checks, use the form:
        #
        #   before :my_permission_check, :only => :foo
        #   def my_permission_check
        #     (current_user.id == params[id] && current_user.has_permission?(:delete_self)) || throw(:halt, :forbidden)
        #   end
        # 
        # TODO.
        # Eventually, we would like this method to automatically check via a synonymous named route symbol
        #
        def authorize_role(*roles)
          (authenticate && current_user.has_role?(*roles)) || throw(:halt, :forbidden)
        end
        
        def authorize_institution(*institutions)
          (authenticate && current_user.has_institution?(*institutions)) || throw(:halt, :forbidden)
        end
        
        #
        # Returns the default name for the current controller & action
        #
        def default_permission
          (controller_name / action_name).to_snake_case
        end

        # Redirect as appropriate when an access request is forbidden (i.e. logged in but disallowed)
        #
        # Override this method in your controllers if you want to have special
        # behavior in case the user is not authorized
        # to access the requested action.  For example, the application might show a pop up window
        # with an explanation.
        def forbidden
          raise Forbidden, "You do not have sufficient privileges"
        end
    
        # Store the URI of the current request in the session.
        #
        # We can return to this location by calling #redirect_back_or_default.
        def store_location
          session[:return_to] = request.uri
        end
    
        # Redirect to the URI stored by the most recent store_location call or
        # to the passed default.
        def redirect_back_or_default(default,opts = {})
          loc = session[:return_to] || default
          session[:return_to] = nil
          redirect loc, opts
        end

        # Called from #current_user.  First attempt to login by the user id stored in the session.
        def login_from_session
          self.current_user = User.get(session[:user]) if session[:user]
        end

        # Called from #current_user.  Now, attempt to login by basic authentication information.
        def login_from_basic_auth
          basic_authentication.authenticate do |email, password|
            self.current_user = User.authenticate(email, password)
          end
        end

        # Called from #current_user.  Finaly, attempt to login by an expiring token in the cookie.
        def login_from_cookie     
          user = cookies[:auth_token] && User.first(:remember_token => cookies[:auth_token])
          if user && user.remember_token?
            user.remember_me
            cookies[:auth_token] = { :value => user.remember_token, :expires => Time.parse(user.remember_token_expires_at.to_s) }
            self.current_user = user
          end
        end
  end# Controller
end # Merb