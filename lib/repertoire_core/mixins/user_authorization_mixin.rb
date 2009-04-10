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
          memberships.all(:reviewed_by => nil, :order => [:created_at]).role
        end  

         # Roles this user has, either directly or by inference        
        def expanded_roles
          Role.self_and_descendants(*roles)
        end
      

        #
        # Authorization checking
        #
        # NOTE.  You can use security methods other than RBAC:
        #        put the appropriate filter in your controller.
        #        For an example, see ensure_institution
        #

        # Check whether user has any of the supplied roles.
        def has_role?(*role_names)
          match_roles = Role.to_roles(*role_names)
          roles.any? { |r| r.implies?(*match_roles) }
        end

        # Check whether user is affiliated with any of the supplied insitutitons (by code).
        def has_institution?(*insitution_codes)
          insitution_codes.include?(self.institution_code)
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
          role = Role.first(:name => role_name)
        
          # TODO.  once DataMapper supports passing in entity models to finders, remove _id
          rejected_requests = self.memberships.all(:role_id => role.id, :reviewer_id => nil, :approved_at.not => nil)
          active_requests   = self.memberships.all(:role_id => role.id)
          relevant_requests = active_requests - rejected_requests

          if relevant_requests.empty?
            Membership.create(:user => self, :role => role)
          else
            relevant_requests.first
          end
        end

        # Grant a role to another user, returning the approved membership request.
        # 
        # Raises an exception if this user lacks permission to grant the role.
        def grant(role_name, user, message=nil)
          role = Role.first(:name => role_name)
          request = nil

          transaction do |t|
            request = Membership.create(:user => user, :role => role)
            request.review(self, true, message) unless request.reviewed?
          end
        
          request
        end
      
        # Approve or reject another user's role membership request
        #
        # @see Memberhsip.review
        def review(membership, approve, message=nil)
          membership.review(self, approve, message)
        end

        # Returns true if user has permissions to grant all the given roles, whether directly or
        # through a role implied by one the user holds directly
        #
        # N.B. expensive operation: use sparingly
        def can_grant?(*role_names)
          implied_roles           = Role.self_and_descendants(*self.roles)
          implied_role_ids        = implied_roles.map { |r| r.id }
          implied_grantable_roles = Role.all(:granted_by_role_id.in => implied_role_ids)
        
          roles_to_check = Role.to_roles(*role_names)
          (roles_to_check - implied_grantable_roles).empty?
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
          user_parent_role_ids = roles.map { |r| r.parent.id }
  
          open_roles     = Role.leaves.all(:granted_by => nil)
          stepwise_roles = Role.all(:id.in => user_parent_role_ids)
        
          (open_roles | stepwise_roles) - (self.roles | self.roles_pending_review)
        end
      

        # Returns list of roles directly marked as grantable by this user
        #
        # Note: will not include roles this user can grant by implication
        def grantable_roles
          role_ids = roles.map { |r| r.id }
          Role.all(:granted_by_role_id.in => role_ids)
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