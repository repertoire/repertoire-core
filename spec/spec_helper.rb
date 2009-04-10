require 'rubygems'
require 'merb-core'
require 'merb-action-args'
require 'merb-slices'
require 'merb-assets'
require 'merb-auth-core'
require 'merb-auth-more'
require 'merb-auth-slice-password'
require 'spec'

require 'dm-core'
require 'dm-validations'

# Configure slices like a real app would
Merb::Plugins.config[:merb_slices][:auto_register] = true
Merb::Plugins.config[:merb_slices][:search_path]   = File.dirname(__FILE__) / '..' / 'lib' / 'repertoire_core.rb'

Merb::Plugins.config[:"merb-auth"][:login_param]    = :email
Merb::Slices::config[:"merb-auth-slice-password"][:no_default_strategies] = true

Merb::Authentication.activate!(:default_password_form)
Merb::Authentication.activate!(:default_basic_auth)

module Merb
  def self.orm
    :datamapper
  end
end

# Set up in-memory database for integration tests
DataMapper.setup(:default, 'sqlite3::memory:')
#DataObjects::Sqlite3.logger = DataObjects::Logger.new(STDOUT, 0)

require 'merb-auth-more/mixins/salted_user'
require File.join(File.expand_path(File.dirname(__FILE__)), "..", "lib", "repertoire_core", "mixins", "user_registration_mixin")
require File.join(File.expand_path(File.dirname(__FILE__)), "..", "lib", "repertoire_core", "mixins", "user_authorization_mixin")
class User
  include DataMapper::Resource
  include Merb::Authentication::Mixins::SaltedUser
  include RepertoireCore::Mixins::UserRegistration
  include RepertoireCore::Mixins::UserAuthorization
  property :id, Serial
end

Merb::Authentication.user_class = User 

class Merb::Authentication

  def fetch_user(session_user_id)
    Merb::Authentication.user_class.get(session_user_id)
  end

  def store_user(user)
    user.nil? ? user : user.id
  end
end

# Using Merb.root below makes sure that the correct root is set for
# - testing standalone, without being installed as a gem and no host application
# - testing from within the host application; its root will be used
Merb.start_environment(
  :testing => true, 
  :adapter => 'runner', 
  :environment => ENV['MERB_ENV'] || 'test',
  :merb_root => Merb.root,
  :session_store => 'memory'
)

class Merb::Mailer
  self.delivery_method = :test_send
end

path = File.dirname(__FILE__)
# Load up all the spec helpers
Dir[path / "spec_helpers" / "**" / "*.rb"].each do |f|
  require f
end

module Merb
  module Test
    module SliceHelper
      
      # The absolute path to the current slice
      def current_slice_root
        @current_slice_root ||= File.expand_path(File.join(File.dirname(__FILE__), '..'))
      end
      
      # Whether the specs are being run from a host application or standalone
      def standalone?
        not $SLICED_APP
      end
      
    end
  end
end

Spec::Runner.configure do |config|
  config.include(Merb::Test::ViewHelper)
  config.include(Merb::Test::RouteHelper)
  config.include(Merb::Test::ControllerHelper)
  config.include(Merb::Test::SliceHelper)
  config.include(ValidModelHashes)
  
  config.before(:each) do
    if standalone?
      Merb::Router.prepare do
       slice(:merb_auth_slice_password, :name_prefix => nil, :path_prefix => "")
       slice(:repertoire_core, :name_prefix => nil, :path_prefix => "")
      end
    end
  end
end
