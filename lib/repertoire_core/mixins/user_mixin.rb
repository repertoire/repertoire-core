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
          has n, :reviews, :class_name => 'Role', :child_key => [:reviewed_by]
          
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
          memberships.all(:approved_at.not => nil).role
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

        # returns false if the user has registered but not activated
        def activated?
         return false if self.new_record?
         !! activation_code.nil?
        end

        # Creates and returns a new activation code
        def make_activation_code
          self.activation_code = self.class.make_key
        end
  
        #
        # Authorization
        #
        # NOTE.  You can use security methods other than RBAC:
        #        put the appropriate filter in your controller.
        #        For an example, see has_institution?
        #
  
        # Check whether user has any of the supplied roles.  Use this in a filter to control access.
        def has_role?(*role_names)
          match_roles = role_names.to_roles
          roles.any? { |r| r.implies?(*match_roles) }
        end
  
        # Check whether user is affiliated with any of the supplied insitutitons (by code).  Use this in a filter to control access.
        def has_institution?(*insitution_codes)
          insitution_codes.include?(self.institution_code)
        end
  
        # returns all roles this user could subscribe to 
        def subscribable_roles
          # list of all parents of user's roles that are subscribable
          user_parent_role_ids = roles.map { |r| r.parent.id }
    
          open_roles     = Role.leaves.all(:reviewed_by.not => nil)
          stepwise_roles = Role.all(:reviewed_by.not => nil, :id.in => user_parent_role_ids)
    
          (open_roles | stepwise_roles).uniq
        end

        # Subscribe user to a new role (passed as symbol or object).
        def subscribe(role_name, message=nil)
          role = role_name.to_role
          raise "#{role_name} is not subscribable" unless subscribable_roles.include?(role)
          m = Membership.create(:user => user, :role => role).save!
          save
          reload
        end

        # returns the roles this user can grant
        def grantable_roles
          user_role_ids = roles.map { |r| r.id }
          Role.all(:granted_by.in => user_role_ids)
        end

        # current user grants role to another user.  raises an exception if this is disallowed.
        def grant(role_name, user, message=nil)
          role = role_name.to_role
          user.transaction do |t|
            membership = Membership.create(:user => user, :role => role)
            membership.save!
            membership.review(self, true, message) unless membership.reviewed?
            user.save
            user.reload
          end
          user
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