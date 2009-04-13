module RepertoireCore
  
  module Mixins
  
    module AuthorizationHelper  
      protected
      # This is the main method to use as a before filter.  You call it with a list of
      # role names, which are checked in order.  If the currently authenticated user
      # has any role that implies one of the listed roles, the filter passes and 
      # the action proceeds.  Otherwise the Forbidden exception will be raised.
      #
      # Use the :message key in the options hash to pass in a failure message to the
      # exception.
      # 
      # === Example
      #
      #    class MyController < Application
      #      before :ensure_authorized, :with => [:foo_member, {:message => "You need to be a privileged FOO MEMBER to see this page!"}]
      #       #... <snip>
      #    end
      # 
      def require_role!(*args)
        session.authenticate!(request, params) unless session.authenticated?
      
        opts = args.last.kind_of?(Hash) ? args.pop : {}
        roles = args.flatten
      
        session.user.has_role?(*roles) || raise(Forbidden, opts[:message])
      end
      
      # convenience alias for users wanting a filter like merb-auth's ensure_authenticated
      alias_method :ensure_authorized, :require_role!
    
      # If the currently authenticated user belongs to one of the institution codes
      # listed, the filter passes.  Otherwise the Forbidden exception will be
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
      def require_institution(*rest)
        session.authenticate!(request, params) unless session.authenticated?
      
        opts = rest.last.kind_of?(Hash) ? rest.pop : {}
        codes = rest.flatten
      
        session.user.has_institution?(*codes) || raise(Forbidden, opts[:message])
      end
      
      # convenience alias for users wanting a filter like merb-auth's ensure_authenticated
      alias_method :ensure_institution, :require_institution
    end
  end
end
