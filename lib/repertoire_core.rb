if defined?(Merb::Plugins)

  $:.unshift File.dirname(__FILE__)
  
  require 'digest/sha1'
  
  require 'repertoire_core/smtp_tls'
  require 'repertoire_core/whois_helper'
  
  raise "RepertoireCore: Currently only datamapper is supported ORM" unless Merb.orm == :datamapper
  
  # Allow all controllers to check current_user / authenticated? etc.
  require 'repertoire_core/controller.rb'
  require 'repertoire_core/exceptions.rb'
 
  load_dependency 'merb-slices'
  Merb::Plugins.add_rakefiles "repertoire_core/merbtasks", "repertoire_core/slicetasks"

  # Register the Slice for the current host application
  Merb::Slices::register(__FILE__)
  
  # Slice configuration - set this in a before_app_loads callback.
  # By default a Slice uses its own layout, so you can swicht to 
  # the main application layout or no layout at all if needed.
  # 
  # Configuration options:
  # :layout - the layout to use; defaults to :repertoire_core
  # :mirror - which path component types to use on copy operations; defaults to all
  Merb::Slices::config[:repertoire_core][:layout] ||= :repertoire_core
  Merb::Slices::config[:repertoire_core][:email_from] ||= 'repertoire@mit.edu'
  
  # All Slice code is expected to be namespaced inside a module
  module RepertoireCore
    
    # Slice metadata
    self.description = "RepertoireCore provides logins, registration, roles, and administration to Repertoire projects"
    self.version = "0.3.1"
    self.author = "Christopher York"
    
    # Stub classes loaded hook - runs before LoadClasses BootLoader
    # right after a slice's classes have been loaded internally.
    def self.loaded
      
      # Repertoire defaults for mailer... redeclare in your project if necessary
      Merb::Mailer.config = {
        :host   => 'smtp.gmail.com',
        :port   => '587',
        :user   => 'hyperstudio.repertoire',
        :pass   => '77MassAve',
        :auth   => :plain
      }

      #Merb::Mailer.config = {
      #  :host   => 'outgoing.mit.edu',
      #  :port   => '587',
      #  :user   => 'repertoire',
      #  :pass   => 'hyperstudio',
      #  :auth   => :plain,
      #  :domain => 'ndakinna.mit.edu'
      #}

    end
    
    # Initialization hook - runs before AfterAppLoads BootLoader
    def self.init

    end
    
    # Activation hook - runs after AfterAppLoads BootLoader
    def self.activate
    end
    
    # Deactivation hook - triggered by Merb::Slices.deactivate(RepertoireCore)
    def self.deactivate
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
      
      # authentication
      
      scope.match("/login" ).to(:controller => "sessions", :action => "create" ).name(:login)
      scope.match("/logout").to(:controller => "sessions", :action => "destroy").name(:logout)
      
      # user registration and management
      
      scope.resources :users, :name_prefix => ''
      
      scope.to(:controller => "users") do |c|
        c.match("/signup").to(                   :action => "new").name(                        :signup)
        c.match("/activate/:activation_code").to(:action => "activate").name(                   :user_activation)
        c.match("/forgot_password").to(          :action => "forgot_password").name(            :forgot_password)
        c.match("/update_password").to(          :action => "update_password").name(            :update_password)
        c.match("/reset_password").to(           :action => "reset_password").name(             :reset_password)
        c.match("/grant", :method => "post").to( :action => "grant").name(                      :grant)
        # c.match("/review", :method => "put").to( :action => "review").name(                     :review)
        c.match("/subscribe", :method => "post").to( :action => "subscribe").name(              :subscribe)
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
  
  # Add dependencies for other RepertoireCore classes below. Example:
  dependency 'merb-mailer'
  dependency 'merb-assets'
  dependency 'merb_helpers'

#  dependency 'dm-constraints'    # in datamapper 0.96, dm-constraints is broken 
  dependency 'dm-validations'
  dependency 'dm-timestamps'
  dependency 'dm-aggregates'

  dependency 'dm-is-nested_set'
  dependency 'dm-is-list'
  
end