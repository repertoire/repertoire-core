module Merb
  module MembershipsHelper

    def navigation(current = nil)
      can_grant = !session.user.grantable_roles.empty?
      
      tag :div, :class => 'navigation' do
        links = []
        links << link_to('Review Requests', slice_url(:repertoire_core, :requests, :shortname => session.user.shortname),         opts(:requests, current)) if can_grant
        links << link_to('Search Users',    slice_url(:repertoire_core, :users),                                                  opts(:search, current))   if can_grant
        links << link_to('My History',      slice_url(:repertoire_core, :user_memberships, :shortname => session.user.shortname), opts(:history, current))
        links << link_to('Log off',         slice_url(:merb_auth_slice_password, :logout),                                        opts(:logout, current))
        links.join
      end
    end
    
    def status_msg(membership)
      case 
        when !membership.reviewed? then "Pending"
        when membership.approved?  then "Approved #{time_lost_in_words membership.approved_at, Time.now, true} ago"  
        when membership.rejected?  then "Declined #{time_lost_in_words membership.updated_at, Time.now, true} ago"  
      end
    end
    
    private 
    
    def opts(name, current, opts = {})
      opts = opts.dup
      (opts[:class] ||= []) << 'current' if name == current
      opts
    end
  end
end # Merb