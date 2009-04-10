module RepertoireCore
  module Mixins
    module User
      
      def self.included(base)
        base.class_eval do
          property :shortname,                  String,   :nullable => false, :unique => true

          property :last_name,                  String,   :nullable => false
          property :first_name,                 String,   :nullable => false
          property :bio,                        DataMapper::Types::Text
  
          property :email,                      String,   :nullable => false, :unique => true
          property :institution,                String
          property :institution_code,           String
  
          property :activated_at,               DateTime
          property :activation_code,            String
          property :password_reset_key,         String, :writer => :protected

          property :created_at,                 DateTime
          property :updated_at,                 DateTime
  
          has n, :memberships
          
          # requires use of salted password mixin...
          # TODO. raise exception if app doesn't require salted password use already
          validates_length :password, :within => 5..20, :if => proc{|m| m.password_required?}
          validates_format :email, :as => :email_address
          validates_format :shortname, :with => /^\w+$/, :message => 'Shortname can be letters and numbers only'

          before :valid?, :make_shortname
          before :save,   :encrypt_password
          before :create, :make_activation_code          

          include RepertoireCore::Mixins::User::InstanceMethods
          extend  RepertoireCore::Mixins::User::ClassMethods
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
  
        #
        # Registration and activation
        #

        # Activate a user email programmatically, sending confirmation
        def activate
          set_activated_data!
          lookup_institution!
          self.save
        end

        # Returns false if the user has registered but not activated
        def activated?
         return false if self.new_record?
         !! activation_code.nil?
        end

        # Creates and returns a new activation code
        def make_activation_code
          self.activation_code = self.class.make_key
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
        # Forgotten password support
        #

        def forgot_password! 
          # Must be a unique password key before it goes in the database
          pwreset_key_success = false
          until pwreset_key_success
            self.password_reset_key = self.class.make_key
            self.save
            pwreset_key_success = self.errors.on(:password_reset_key).nil? ? true : false 
          end
        end

        def forgotten_password?
          self.password_reset_key != nil
        end

        def clear_forgotten_password!
          self.password_reset_key = nil
          self.save
        end
  
        #
        # Utility functions on instance
        #
  
        def full_name
          "#{first_name} #{last_name}"
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
        
        protected
        
        def make_shortname
          self.shortname = default_shortname if self.shortname.blank?
        end
        
        # returns a shortname based on email that's guaranteed not to exist yet
        def default_shortname
          self.email =~ /^(.*)\@/
          prefix = $1 || "#{first_name}#{last_name}"
          prefix = prefix.downcase.gsub(/\W+/, '')
          suffix = nil

          while self.class.first(:shortname => "#{prefix}#{suffix}") do
             suffix ||= 0
             suffix += 1
          end
          "#{prefix}#{suffix}"
        end
  
        def set_activated_data!
          self.activated_at = DateTime.now
          self.activation_code = nil

          true
        end

       # Roles this user has, either directly or by inference        
        def expanded_roles
        end
      end
      
      module ClassMethods
        # Creates and returns a unique hexdigested key
        def make_key
          Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
        end
      end
    end
  end
end