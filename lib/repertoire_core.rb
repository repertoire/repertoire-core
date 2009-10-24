if defined?(Merb::Plugins)

  $:.unshift File.dirname(__FILE__)
  
  raise "RepertoireCore: Currently only datamapper is supported ORM" unless Merb.orm == :datamapper
  
  require 'repertoire_core/exceptions'
  require 'repertoire_core/whois_helper'
  require 'repertoire_core/mixins/authorization_helper'
  require 'repertoire_core/mixins/user_properties_mixin'
  require 'repertoire_core/mixins/user_authorization_mixin'
  require 'repertoire_core/mixins/user_mixin'
  require 'repertoire_core/mixins/dm/resource_mixin'
  
  # dependency 'merb-slices', :immediate => true
  Merb::Plugins.add_rakefiles "repertoire_core/merbtasks", "repertoire_core/slicetasks", "repertoire_core/spectasks"

  # Register the Slice for the current host application
  Merb::Slices::register(__FILE__)
  
  # Slice configuration - set this in a before_app_loads callback.
  # By default a Slice uses its own layout, so you can swicht to 
  # the main application layout or no layout at all if needed.
  # 
  # Configuration options:
  # :layout - the layout to use; defaults to :repertoire_core
  # :mirror - which path component types to use on copy operations; defaults to all
  Merb::Slices::config[:repertoire_core][:layout]         ||= :core
  Merb::Slices::config[:repertoire_core][:email_from]     ||= 'repertoire@mit.edu'
  Merb::Slices::config[:repertoire_core][:lookup_helpers] ||= [ RepertoireCore::WhoisHelper.new ]
  
  # All Slice code is expected to be namespaced inside a module
  module RepertoireCore
    
    # Slice metadata
    self.description = "RepertoireCore provides registration, RBAC, and other tools to Repertoire projects"
    self.version = "0.3.2"
    self.author = "Christopher York"
    
    # Stub classes loaded hook - runs before LoadClasses BootLoader
    # right after a slice's classes have been loaded internally.
    def self.loaded
    
      # Repertoire defaults for mailer... redeclare in your project if necessary
      
      # First default (standard): sendmail
      Merb::Mailer.config = {:sendmail_path => '/usr/sbin/sendmail'}
      Merb::Mailer.delivery_method = :sendmail
      
      # Other options - SMTP vis SSH/TLS to either GMAIL or MIT email
      
      # Activate SSL Support
      # Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
      
      # Merb::Mailer.config = {
      #   :host   => 'smtp.gmail.com',
      #   :port   => '587',
      #   :user   => 'repertoire.hyperstudio',
      #   :pass   => '77MassAve',
      #   :auth   => :plain
      # }
      
      #Merb::Mailer.config = {
      #  :host   => 'outgoing.mit.edu',
      #  :port   => '587',
      #  :user   => '<your kerberos id>',
      #  :pass   => '<your password>',
      #  :auth   => :plain,
      #  :domain => 'scrubbing-bubbles.mit.edu'
      #}

    end
    
    # Initialization hook - runs before AfterAppLoads BootLoader
    def self.init
      Merb::Authentication.after_authentication do |user, request, params|
        # Only allow activated accounts to log in
        user.activated? ? user : nil
      end
      
      # extend controllers to allow authorization checks
      Merb::Controller.class_eval do
        include RepertoireCore::Mixins::AuthorizationHelper
      end
    end
    
    # Activation hook - runs after AfterAppLoads BootLoader
    def self.activate
    end
    
    # Deactivation hook - triggered by Merb::Slices.deactivate(RepertoireCore)
    def self.deactivate
      Merb::Authentication.after_authentication do |user, request, params|
        user
      end
    end
    
    # Setup routes inside the host application
    #
    # @param scope<Merb::Router::Behaviour>
    #  Routes will be added within this scope (namespace). In fact, any 
    #  router behaviour is a valid namespace, so you can attach
    #  routes at any level of your router setup.
    #
    # @note prefix your named routes with :repertoire_core_
    #   to avoid potential conflicts with global named routes.
    def self.setup_router(scope)
      
      # user profile updates 
      # TODO. authenticate
      scope.identify(User => :shortname) do
        scope.resources :users, :key => :shortname do |user|
          user.resources :memberships
        end
      end
      
      # TODO.  rework this into a REST style route with its own controller
      scope.match("/users/:shortname/requests").to(:action => 'requests', :controller => 'users').name(:requests)

      # user registration and passwords      
      scope.to(:controller => "users") do |c|
        c.match("/signup").to(                   :action => "new").name(                     :signup)
        c.match("/activate/:activation_code").to(:action => "activate").name(                :activate)
        c.match("/forgot_password").to(          :action => "forgot_password").name(         :forgot_password)
        c.match("/password_reset_key").to(       :action => "password_reset_key").name(      :password_reset_key)
        c.match("/reset_password").to(           :action => "reset_password").name(          :reset_password)
        c.match("/update_password").to(          :action => "update_password").name(         :update_password)
        
        c.match("/webservice/complete_name").to(    :action => "complete_name").name(           :complete_name)
        c.match("/webservice/validate").to(         :action => "validate_user").name(           :validate_user)
        c.match("/webservice/validate_reset_password").to(  :action => "validate_reset_password").name( :validate_reset_password )
      end
    end
  end
  
  # Setup the slice layout for RepertoireCore
  #
  # Use RepertoireCore.push_path and RepertoireCore.push_app_path
  # to set paths to repertoire_core-level and app-level paths. Example:
  #
  # RepertoireCore.push_path(:application, RepertoireCore.root)
  # RepertoireCore.push_app_path(:application, Merb.root / 'slices' / 'repertoire_core')
  # ...
  #
  # Any component path that hasn't been set will default to RepertoireCore.root
  #
  # Or just call setup_default_structure! to setup a basic Merb MVC structure.
  RepertoireCore.setup_default_structure!

  # CWY 10/24/2009.  Dependencies are redundant using new bundler... see the rakefile/gemspec
  
  # Add dependencies for other RepertoireCore classes below.
  # Don't forget to copy this list to the Rakefile!
  #merb_gems_version = ">=1.1"
  #dm_gems_version   = ">=0.10"
  #do_gems_version   = ">=0.10"
  
  #dependency 'merb-mailer', merb_gems_version
  #dependency 'merb-assets', merb_gems_version
  #dependency 'merb-auth-core', merb_gems_version
  #dependency 'merb-auth-more', merb_gems_version
  #dependency 'merb-auth-slice-password', merb_gems_version
  #dependency 'merb-helpers', merb_gems_version

  #dependency 'dm-core', dm_gems_version
  # dependency 'dm-constraints', dm_gems_version    # in datamapper 0.9.10+, dm-constraints is broken 
  #dependency 'dm-validations', dm_gems_version
  #dependency 'dm-timestamps', dm_gems_version
  #dependency 'dm-aggregates', dm_gems_version

  #dependency 'dm-is-nested_set', dm_gems_version
  #dependency 'dm-is-list', dm_gems_version
  
  #dependency 'whois', '>=0.5.2'
  #dependency 'tlsmail', '>=0.0.1'
end