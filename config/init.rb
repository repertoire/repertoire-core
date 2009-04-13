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
  DataObjects::Sqlite3.logger = DataObjects::Logger.new(STDOUT, 0)
  DataMapper.auto_migrate!

  u = User.new(:email => 'lorpgui@yahoo.com', :first_name => 'l', :last_name => 'g', :shortname => 'lorpie')
  u.password = u.password_confirmation = 'lllll'
  u.save!
  u.activate
  
  u2 = User.new(:email => 'guilorp@yahoo.com', :first_name => 'l', :last_name => 'gz', :shortname => 'lorpiez')
  u2.password = u.password_confirmation = 'lllll'
  u2.save!
  u2.activate

  Role.declare do
    Role[:admin,   "System Administrator"]
    Role[:foo_manager, "Manager, Foo Project"]
    Role[:foo_member,  "Member, Foo Project"] 
    Role[:foo_guest,   "Guest, Foo Project"]
    
    Role[:admin].
      grants(:foo_manager).
      grants(:foo_member).open.
      implies(:guest).open
  end
  
  Role.grant!(:foo_guest, u)
  Membership.create(:user => u, :reviewer => u, :role => Role[:admin])
  Role.grant! :foo_manager, u2, <<-TEXT
  William Jefferson "Bill" Clinton (born William Jefferson Blythe III, August 19, 1946)[1] is a former President of the United States. He served as the 42nd President from 1993 to 2001. He was the third-youngest president; only Theodore Roosevelt and John F. Kennedy were younger when entering office. He became president at the end of the Cold War, and as he was born in the period after World War II, is known as the first Baby Boomer president.[2] His wife, Hillary Rodham Clinton, is currently the United States Secretary of State. She was previously a United States Senator from New York, and also candidate for the Democratic presidential nomination in 2008.
  TEXT
  u.subscribe :foo_member, <<-TEXT
  Clinton left office with an approval rating at 66%, the highest end of office rating of any president since World War II.[12] Since then, he has been involved in public speaking and humanitarian work. Clinton created the William J. Clinton Foundation to promote and address international causes such as treatment and prevention of HIV/AIDS and global warming.
  TEXT
end