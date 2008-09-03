module RepertoireCore
  module Exceptions
    
    # NOTE! when modifying this file, all new methods need to be registered with show_action (see included)
    
    # when used in a controller, make sure these actions are available
    def self.included(base)
      base.send(:include, Merb::RepertoireCore::ApplicationHelper)
      base.controller_for_slice RepertoireCore
      base.show_action :forbidden, :standard_error
    end

    # 
    # 403: Forbidden [ i.e. user authenticated but had insufficient permissions
    #
    def forbidden
      @exception = request.exceptions.first
      render :format => :html
    end
  
    #
    # Application errors: email developer and display a message page
    #
  
    def standard_error
      @exception = request.exceptions.first
      render :standard_error, :format => :html
    end
  end
end