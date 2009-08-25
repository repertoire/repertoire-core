module RepertoireCore
  module Mixins
    module UserAuthorization
      
      def self.included(base)
        base.class_eval do
          
          has n, :memberships
          
          include RepertoireCore::Mixins::UserAuthorization::InstanceMethods
          extend  RepertoireCore::Mixins::UserAuthorization::ClassMethods
        end
      end
    
      module InstanceMethods

        # @returns the set of approved roles for this user
        def roles
          memberships.all(:approved_at.not => nil, :order => [:approved_at]).role
        end
      
        # @returns the set of roles under membership review for this user
        def roles_pending_review
          memberships.all(:reviewer_id => nil, :order => [:created_at]).role
        end  

         # Roles this user has, either directly or by inference        
        def expanded_roles
          Role.self_and_descendants(*self.roles)
        end
        
        # Provide a list of membership requests relevant to the given role (as context for review decisions)
        #
        # Specifically, returns all membership requests by this user, for roles that encompass, equal, or
        # are encompassed by the given role.
        #
        # If no role name is provided, the entire history will be returned.
        def history(role_name=nil)
          if role_name.nil?
            self.memberships
          else
            role             = Role[role_name]
            related_roles    = role.ancestors | role.self_and_descendants
            related_role_ids = related_roles.map { |r| r.id }        # DM TODO.  related_roles.memberships ...
           self.memberships.all(:user_id => self.id, :role_id => related_role_ids)
          end
        end

        #
        # Authorization checking
        #
        # NOTE.  You can use security methods other than RBAC:
        #        put the appropriate filter in your controller.
        #        For an example, see ensure_institution
        #

        # Check whether user has any of the supplied roles,
        # either directly or by implication.
        #
        # @returns the first matching role, or nil
        def has_role?(*role_names)
          match_roles = Role.to_roles(*role_names)
          self.roles.any? { |r| r.implies?(*match_roles) }
        end

        # Check whether user is affiliated with any of the supplied institutions (by code).
        def has_institution?(*institution_codes)
          institution_codes.include?(self.institution_code)
        end
      
        #
        # Subscription to new roles
        #

        # User subscribes to a new role, and returns the membership request.  If the user already has the role
        # or is under review for it, that request is returned instead.
        #
        # Depending on the role it may approve immediately.  Note that this method does not notify
        # the role's reviewer.        
        #
        # Semantically it is equivalent to self.grant(:foo, self), except it doesn't raise an exception if
        # review doesn't pass immediately.
        def subscribe(role_name, message=nil)
          role = Role[role_name]
        
          # TODO.  once DataMapper supports passing in entity models to finders, remove _id
          prior_requests = self.memberships.all(:role_id => role.id)
          approved = prior_requests.find { |r| r.approved? }
          pending  = prior_requests.find { |r| !r.reviewed? }
          
          approved || pending || Membership.create(:user => self, :role => role, :user_note => message)
        end

        # Grant a role to another user, returning the approved membership request.
        #
        # If the user already has the role, the existing membership request is
        # returned; if the user has an existing request pending, that one is approved.
        # 
        # Raises an exception if this user lacks permission to grant the role.
        def grant(role_name, user, message=nil)
          role    = Role[role_name]
          request = nil
          
          # TODO.  once DataMapper supports passing in entity models to finders, remove _id
          prior_requests = user.memberships.all(:role_id => role.id)
          
          transaction do |t|
            approved = prior_requests.find { |r| r.approved? }
            pending  = prior_requests.find { |r| !r.reviewed? }
            request  = approved || pending || Membership.create(:user => user, :role => role)
            
            request.review(self, true, message) unless request.reviewed?
            request.reload
          end
          
          request
        end
      
        # Approve or reject another user's role membership request
        #
        # @see Memberhsip.review
        def review(membership, approve, message=nil)
          membership.review(self, approve, message)
        end
        
        # Returns pending membership requests this user is authorized to review, ordered by application date
        #
        # N.B. expensive operation: use sparingly
        def requests_to_review
          roles = Role.to_roles(*self.implied_grantable_roles)
          role_ids = roles.map { |r| r.id }            # DM TODO.  why not role.memberships?
          Membership.all(:role_id => role_ids, :reviewer_id => nil, :order => [:created_at])
        end

        # Returns true if user has permissions to grant all the given roles, whether directly or
        # through a role implied by one the user holds directly
        #
        # N.B. expensive operation: use sparingly
        def can_grant?(*role_names)
          roles_to_check = Role.to_roles(*role_names)
          (roles_to_check - self.implied_grantable_roles).empty?
        end
      
        # 
        # Common UI access for subscription and granting
        #
      
        # Returns all roles this user might want to subscribe to, for presentation in user interfaces.
        #
        # Because the list of all potential subscribable roles could include everything in the system, it is
        # pruned as follows:
        #
        #   - roles with open subscription are always included
        #   - only roles that are "one step better" than the ones the user already has are given
        #   - roles the user already has or is under review for are removed
        #
        def subscribable_roles
          user_parent_role_ids = self.roles.map { |r| r.parent.id }
  
          entry_roles     = Role.entry_roles
          stepwise_roles  = Role.all(:id => user_parent_role_ids, :subscribable => true)    # DM TODO.  why not self.parents ?
          subscribable_roles = entry_roles | stepwise_roles
          
          subscribable_roles.delete_if { |r| self.has_role?(r) }
          subscribable_roles - self.roles_pending_review
        end
      

        # Returns list of roles directly marked as grantable by this user
        #
        # If another user is supplied, the result is pruned by their current and pending roles
        #
        # Note: will not include roles this user can grant by implication
        def grantable_roles(user = nil)
          role_ids = self.roles.map { |r| r.id }
          grantable_roles = Role.all(:granted_by_role_id => role_ids)    # DM TODO.  why not self.roles.grants  ?
          
          unless user.nil?
            grantable_roles.delete_if { |r| user.has_role?(r) }
            grantable_roles -= user.roles_pending_review
          end
          
          grantable_roles
        end      
        
        
        # Returns the list of all roles grantable by this user, whether directly or by implication
        #
        # N.B. expensive operation; use sparingly
        def implied_grantable_roles
          implied_roles           = Role.self_and_descendants(*self.roles)
          implied_role_ids        = implied_roles.map { |r| r.id }
          implied_grantable_roles = Role.all(:granted_by_role_id => implied_role_ids)    # DM TODO.  why not implied_roles.grants ?
        end
      
        #
        # Utility functions
        #
      
        def lookup_institution!
          helpers = RepertoireCore.config[:lookup_helpers]

          helpers.detect do |helper|
            helper.lookup!(self)
          end
        end
      end
      
      module ClassMethods
        # None
      end
    end
  end
end
