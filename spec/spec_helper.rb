require 'rubygems'
require 'merb-core'
require 'merb-slices'
require 'merb-assets'
require 'spec'

require 'dm-core'

# Add repertoire_core.rb to the search path
Merb::Plugins.config[:merb_slices][:auto_register] = true
Merb::Plugins.config[:merb_slices][:search_path]   = File.dirname(__FILE__) / '..' / 'lib' / 'repertoire_core.rb'

module Merb
  def self.orm
    :datamapper
  end
end

# Set up in-memory database for integration tests
DataMapper.setup(:default, 'sqlite3::memory:')

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
    Merb::Router.prepare { |r| r.slice(:RepertoireCore, :path_prefix => 'repertoire_core', :name_prefix => nil) } if standalone?
  end
end
