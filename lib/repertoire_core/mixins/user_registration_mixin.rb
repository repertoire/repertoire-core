module RepertoireCore
  module Mixins
    module UserRegistration
      
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
          
          # requires use of salted password mixin...
          # TODO. raise exception if app doesn't require salted password use already
          validates_length :password, :within => 5..20, :if => proc{|m| m.password_required?}
          validates_format :email, :as => :email_address
          validates_format :shortname, :with => /^\w+$/, :message => 'Shortname can be letters and numbers only'

          before :valid?, :make_shortname
          before :save,   :encrypt_password
          before :create, :make_activation_code          

          include RepertoireCore::Mixins::UserRegistration::InstanceMethods
          extend  RepertoireCore::Mixins::UserRegistration::ClassMethods
        end
      end
      
      module InstanceMethods
  
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