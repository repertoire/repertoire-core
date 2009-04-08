module RepertoireCore
  
  module AuthorizedHelper  
    protected
    # This is the main method to use as a before filter.  You call it with a list of
    # role names, which are checked in order.  If the currently authenticated user
    # has any role that implies one of the listed roles, the filter passes and 
    # the action proceeds.  Otherwise the Unauthorized exception will be raised.
    #
    # Use the :message key in the options hash to pass in a failure message to the
    # exception.
    # 
    # === Example
    #
    #    class MyController < Application
    #      before :ensure_authenticated
    #      before :ensure_authorized, :with => [:system_administrator, :ber_manager, :message => "Failed authorization"]
    #       #... <snip>
    #    end
    # 
    def ensure_authenticated(*rest)
      session.authenticate!(request, params) unless session.authenticated?
      
      opts = rest.last.kind_of?(Hash) ? rest.pop : {}
      roles = rest.flatten
      
      key_role = session.user.has_role?(*roles)
      
      raise Merb::ControllerExceptions::Unauthorized, opts[:message] unless key_role
      key_role
    end
    
    # If the currently authenticated user belongs to one of the institution codes
    # listed, the filter passes.  Otherwise the Unauthorized exception will be
    # raised.
    #
    # Use the :message key in the options hash to pass in a failure message to the
    # exception.
    # 
    # === Example
    #
    #    class MyController < Application
    #      before :ensure_authenticated
    #      before :ensure_authorized, :with => ['MIT-2', 'YALEU', :message => "Failed authorization"]
    #       #... <snip>
    #    end
    #
    def ensure_institution(*rest)
      session.authenticate!(request, params) unless session.authenticated?
      
      opts = rest.last.kind_of?(Hash) ? rest.pop : {}
      codes = rest.flatten
      
      key_code = session.user.has_institution?(*codes)
      
      raise Merb::ControllerExceptions::Unauthorized, opts[:message] unless key_code
      key_code
    end
  end
end
