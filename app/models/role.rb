class Role
  include DataMapper::Resource

  property :id,                         Serial
  
  # core information for hierarchical RBAC
  property :name,                       String,  :nullable => false, :unique => true
  property :title,                      String
  is :nested_set
  
  has n, :memberships
  
  # granting and subscription control
  belongs_to :granted_by, :class_name => self.name, :child_key => [:granted_by_role_id], :order => [:lft.asc]
  property   :subscribable,             Boolean, :nullable => false, :default => false
  
  # administrative
  property :created_at,                 DateTime
  property :updated_at,                 DateTime
  
  # TODO if we used role.lft as the self-referential foreign key for granted_by instead of role.id, 
  #      doing grant checks would be a simple join...  not top priority since grants are very rare
  
  # N.B. The subscribable property determines whether an empty grantor means "open to everyone" or
  #      "open to no-one."  A non-subscribable role with no grantor can only be granted by the command line
  #      administrator.  A subscribable role with no grantor can be joined by anyone, without review.
      
  # 
  # Role member access
  #
  
  # @returns all of this role's approved members
  def members
    memberships(:approved_at.not => nil, :order => [:approved_at]).user
  end
  
  # @returns all of the users qualified to grant this role
  def grantors
    granted_by.members
  end
      
  #
  # Role status
  #
  
  # @returns true if role has open membership policy
  # subscriptions to an open role approve automatically, without review
  def open_membership?
    self.subscribable && self.granted_by.nil?
  end
  
  # @returns true if the role's membership is closed
  # membership in a closed role can only be granted at the console, not by other users
  def closed_membership?
    !self.subscribable && self.granted_by.nil?
  end
  
  # @returns true if this role implies any of the provided ones
  def implies?(*others)
    Role.to_roles(*others).any? { |r| (lft..rgt).include?(r.lft) }
  end
  
  #
  # Convenience methods
  #
  
  # Provides a rough numeric approximation of the role's importance
  # vis-a-vis all other declared roles, for sorting lists of roles.
  #
  # Current implementation guarantees (1) related roles will be grouped
  # together; (2) within each group, roles with more permissions will
  # appear first.  
  #
  # This does *not* mean, however, that a role necessarily has lower
  # permissions because it appears later in the list; it might just be in
  # a different group of roles.
  def sort_order
    lft
  end
  
  def <=>(other)
    self.lft <=> other.lft
  end
  
  #
  # Class methods
  #
  
  class << self
    
    # Grant a role to user by fiat, without any review process. Intended primarily for use in command-line 
    # user administration.  Do not call programmatically.
    #
    # @returns the approved membership record, with a nil reviewed_by field
    #
    def grant!(role_name, user, message=nil)
      Merb.logger.warn("Deus ex machina grant of :#{role_name} to #{user.full_name} at #{Time.now}")
      request = nil
      
      role = Role[role_name]
      prior_requests = user.memberships.all(:role_id => role.id)
      
      transaction do |t|
        approved = prior_requests.find { |r| r.approved? }
        pending  = prior_requests.find { |r| !r.reviewed? }
        request  = approved || pending || Membership.create(:user => user, :role => role)

        unless request.approved?
          request.approved_at   = Time.now
          request.reviewer_note = message
        end
        
        request.save!
        request.reload
      end
      
      request
    end
    
    # Look up a role (normal use), or declare a role (declaration context)
    #
    # Role.declare do
    #   Role[:admin, "The system administrator"]     # can also be used to re-title a role
    # end
    #
    # later...
    #   Role[:admin].open_membership?
    #
    # N.B. it is rarely necessary to look up a role.  Instead use role symbols:
    #   jack.grant(:editor, jill)
    #
    # @returns the role object
    #
    def [](name, title=nil)
      if @declarator
        role = Role.first_or_create(:name => name)
        if title && title != role.title
          role.title = title
          role.save!
        end
        @declarator.state = role
        @declarator
      else
        Role.first(:name => name) || raise("Unkown role :#{name}")
      end
    end
    
    
    # Declare new roles and role relationships
    #
    # Role.declare do |base|
    #  Role[:admin, "The company administrator"]
    #  Role[:secretary, "The office secretary"]
    #  
    #  Role[:admin].grants(:secretary)
    #  Role[:secretary].implies(:manager)
    #  
    #  Role[:user].open                                  
    # end
    def declare(&block)
      begin
        @declarator = Declarator.new
        yield @declarator
      ensure
        @declarator = nil
      end
    end

    # 
    # Internal helpers
    #
    
    # Calculates a complete list of all of the roles implied by a base set
    #
    # @params the base role objects
    #
    # @returns a list of roles
    def self_and_descendants(*roles)
      spans = roles.map{ |r| (r.lft)..(r.rgt) }
      spans = spans.map{ |s| s.to_a }.flatten.uniq
      Role.all(:lft.in => spans)
    end
    
    # Loads a set of roles from a mix of symbols and role objects
    #
    # @throws RuntimeException if a role name does not exist
    #
    # @returns the role objects
    def to_roles(*roles)
      # load a series of mixed roles and symbols
      role_names = roles.find_all { |r| r.is_a?(Symbol) }
      load_roles = Role.all(:name.in => role_names)
      raise "Unable to locate all roles in [#{ role_names.join(' ')}]" unless load_roles.size == role_names.size
      (roles - role_names) | load_roles
    end
    
    
    # Returns a list of the entry-level roles: subscribable roles without children
    #
    # These roles represent entry points for user to membership in other projects
    #
    def entry_roles
      Role.leaves.all(:subscribable => true)
    end
  end
  
  
  # 
  # Small DSL for declaring role hierarchies
  #
  # Primarily for use in migrations
  #  
  class Declarator
    attr_accessor :state
  
    # Declare the current role implies (i.e. is parent for) others
    #
    #   Role.declare do
    #     Role[:manager].implies(:member)
    #   end
    #
    def implies(*others)
      others.each do |name|
        r = Role.first_or_create(:name => name)
        r.parent = self.state
        r.save!
      end
      self.state = Role.first(:name => others.last)
      self
    end
    
    # Declare the current role can grant membership for others.
    #
    # If the other roles have no parent yet, the current role becomes
    # their parent.
    #
    #   Role.declare do
    #     Role[:manager].implies(:secretary).implies(:member)
    #     Role[:manager].grant(:member)
    #   end
    #
    def grants(*others)
      others.each do |name|
        r = Role.first_or_create(:name => name)
        r.granted_by = self.state
        r.parent     = self.state if r.parent_id == 1         
        # subtle workaround: dm-is-nested set sets parent_id automatically to root.  
        # parent_id will be 1 (root) if this is a new record.  so set it together with grant
        r.save!
      end
      self.state = Role.first(:name => others.last)
      self
    end

    # Declare the current role should be open to subscription requests.
    #
    # The existing grantor role is unchanged.  Calling open on role without
    # a grantor makes role membership open: no review required.
    #
    #   Role.declare do
    #     Role[:member].open
    #   end  
    def open
      self.state.subscribable = true
      self.state.save!
      self
    end
    
    # Declare the current role should have closed membership.
    #
    # Any existing grantor declaration is cleared.  After calling close on
    # a role only the command line can be used to add/remove members.
    #
    #   Role.declare do
    #     Role[:member].close
    #   end
    def close
      self.state.subscribable = false
      self.state.granted_by   = nil
      self.state.save!
      self
    end
  end
end
