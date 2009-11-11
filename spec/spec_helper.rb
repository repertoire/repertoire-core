# 11/5/2009.  N.B. as of Merb 1.0.15, it doesn't seem to require files properly for spec testing slices.
#                  Probably an effect of the switch to bundling.

env = ENV['MERB_ENV'] || 'test'

require 'rubygems'
require 'merb-core'
require 'merb-slices'
require 'spec'

Merb.load_dependencies(:environment => env)

Merb.start_environment(:testing => true, 
                       :adapter => 'runner', 
                       :environment => env,
                       :session_store => 'memory')

path = File.dirname(__FILE__)
# Load up all the spec helpers
Dir[path / "spec_helpers" / "**" / "*.rb"].each do |f|
  require f
end

# Configure routes

module Merb
  module Test
    module SliceHelper
      
      # The absolute path to the current slice
      def current_slice_root
        @current_slice_root ||= File.expand_path(File.join(File.dirname(__FILE__), '..'))
      end
      
      # Whether the specs are being run from a host application or standalone
      def standalone?
        Merb.root == ::RepertoireCore.root
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
  
  config.before(:all) do
    if standalone?
      Merb::Router.prepare do
       slice(:merb_auth_slice_password, :name_prefix => nil, :path_prefix => "")
       slice(:repertoire_core, :name_prefix => nil, :path_prefix => "")
      end
    end
  end
end
