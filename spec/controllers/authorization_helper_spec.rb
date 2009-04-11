require File.join( File.dirname(__FILE__), "..", "spec_helper" )

include RepertoireCore

describe RepertoireCore::Mixins::AuthorizationHelper do
  
    before(:all) do
      # Setup for some abstract "Item" centric collaboration software
      
      # controller
      class Items < Merb::Controller  
        provides :text

        def index
          require_role(:itm_guest)
          display 'lots of Items'
        end
        def show
          require_role(:itm_guest)
          display 'a single Item'
        end
        def create
          require_role(:itm_member)
          display 'created your Item!'
        end
        def delete
          require_role(:itm_manager)
          display 'deleted that Item!'
        end
      end

      # TODO.  hack to provide html... can't figure out how to get webrat to send http accept header properly
      class String
        def to_html; self; end
      end

      # router
      Merb::Router.reset!
      Merb::Router.prepare do
        slice(:merb_auth_slice_password, :name_prefix => nil, :path_prefix => "")
        slice(:repertoire_core,          :name_prefix => nil, :path_prefix => "")
        
        authenticate do
          # old-style routes since I can't get webrat to send the right HTTP verb to REST resources
          match("/items").to(           :controller => "items", :action => "index")
          match("/items/show/:id").to(  :controller => "items", :action => "show")
          match("/items/create").to(    :controller => "items", :action => "create")
          match("/items/delete/:id").to(:controller => "items", :action => "delete")
        end
      end
      
      User.auto_migrate!
      Role.auto_migrate!
      Membership.auto_migrate!
        
      Role.declare do
        # a typical RBAC arrangement
        Role[:sysadmin].
          implies(:itm_manager).
          grants(:itm_member).
          implies(:itm_guest).open
      end
    
      @nick, @suzy, @tim = (1..3).map { u = User.create(valid_user_hash); u.activate; u }
      Role.grant!(:sysadmin, @nick)
      Role.grant!(:itm_guest, @suzy)
    end
      
    it "should allow and forbid access for a user testing direct role membership" do
      response = request(url(:perform_login), :method => "PUT", :params => { :email => @suzy.email, :password => @suzy.password })
      response.should redirect
      
      request('/items').should be_successful             # index: suzy has :itm_guest
      request('/items/show/1').should be_successful      # show: suzy has :itm_guest
      request('/items/create').status.should == 403      # create: suzy doesn't have :itm_member   
      request('/items/delete/1').status.should == 403    # delete: suzy doesn't have :itm_manager
    end

    it "should allow and forbid access for a user testing inferred role membership" do
      response = request(url(:perform_login), :method => "PUT", :params => { :email => @nick.email, :password => @nick.password })
      response.should redirect
      
      request('/items').should be_successful             # index: nick has :itm_guest
      request('/items/show/1').should be_successful      # show: nick has :itm_guest
      request('/items/create').should be_successful      # create: nick has :itm_member      
      request('/items/delete/1').should be_successful    # delete: nick has :itm_manager
    end
    
    it "should forbid all for a user with no appropriate roles" do
      response = request(url(:perform_login), :method => "PUT", :params => { :email => @tim.email, :password => @tim.password })
      response.should redirect
      
      request('/items').status.should == 403
      request('/items/show/1').status.should == 403
      request('/items/create').status.should == 403
      request('/items/delete/1').status.should == 403
    end
end