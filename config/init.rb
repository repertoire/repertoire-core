#
# ==== Standalone RepertoireCore configuration
# 
# This configuration/environment file is only loaded by bin/slice, which can be 
# used during development of the slice. It has no effect on this slice being
# loaded in a host application. To run your slice in standalone mode, just
# run 'slice' from its directory. The 'slice' command is very similar to
# the 'merb' command, and takes all the same options, including -i to drop 
# into an irb session for example.
#
# The usual Merb configuration directives and init.rb setup methods apply,
# including use_orm and before_app_loads/after_app_loads.
#
# If you need need different configurations for different environments you can 
# even create the specific environment file in config/environments/ just like
# in a regular Merb application. 
#
# In fact, a slice is no different from a normal # Merb application - it only
# differs by the fact that seamlessly integrates into a so called 'host'
# application, which in turn can override or finetune the slice implementation
# code and views.
#

use_orm :datamapper

Merb::Config.use do |c|

  # Sets up a custom session id key which is used for the session persistence
  # cookie name.  If not specified, defaults to '_session_id'.
  # c[:session_id_key] = '_session_id'
  
  # The session_secret_key is only required for the cookie session store.
  c[:session_secret_key]  = '4c943013b421359115672df76eeb5c0355a965a8'
  
  # There are various options here, by default Merb comes with 'cookie', 
  # 'memory', 'memcache' or 'container'.  
  # You can of course use your favorite ORM instead: 
  # 'datamapper', 'sequel' or 'activerecord'.
  c[:session_store] = 'cookie'
  
  # When running a slice standalone, you're usually developing it,
  # so enable template reloading by default.
  c[:reload_templates] = true
  
end

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


# Set up in-memory database for integration tests
DataMapper.setup(:default, 'sqlite3://db/testing.sqlite3')

require 'merb-auth-more/mixins/salted_user'
require File.join(File.expand_path(File.dirname(__FILE__)), "..", "lib", "repertoire_core", "mixins", "user_properties_mixin")
require File.join(File.expand_path(File.dirname(__FILE__)), "..", "lib", "repertoire_core", "mixins", "user_authorization_mixin")
class User
  include DataMapper::Resource
  include Merb::Authentication::Mixins::SaltedUser
  include RepertoireCore::Mixins::UserProperties
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


Merb::BootLoader.before_app_loads do
end
 
Merb::BootLoader.after_app_loads do
  #DataObjects::Sqlite3.logger = DataObjects::Logger.new(STDOUT, 0)
  DataMapper.auto_migrate!

  #require 'config/fixtures'
  
end