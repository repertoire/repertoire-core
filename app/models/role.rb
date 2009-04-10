class Role
  include DataMapper::Resource

  property :id,                         Serial
  
  # core information for hierarchical RBAC
  property :name,                       String,  :nullable => false, :unique => true
  property :title,                      String
  is :nested_set
  
  # granting and subscription control
  belongs_to :granted_by, :class_name => self.name, :child_key => [:granted_by_role_id], :order => [:lft.asc]
  has n,     :grants,     :class_name => self.name, :child_key => [:granted_by_role_id], :order => [:lft.asc]
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
  # Role status
  #
  
  # @returns true if role has open membership policy
  def open_membership?
    self.subscribable && self.granted_by.nil?
  end
  
  # @returns true if the role's membership is closed
  def closed_membership?
    !self.subscribable && self.granted_by.nil?
  end
  
  # @returns true if this role implies any of the provided ones
  def implies?(*others)
    Role.to_roles(*others).any? { |r| (lft..rgt).include?(r.lft) }
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
      
      transaction do |t|
        role = Role[role_name]
        request = Membership.create(:user => user, :role => role, :approved_at => Time.now, :reviewer_note => message)
      end
      
      request
    end
    
    # Look up a role (normal use), or declare a role (declaration context)
    #
    # Role.declare do
    #   Role[:admin, "The system administrator"]
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
        role = Role.first_or_create({:name => name}, {:title => title})
        @declarator.state = role
        @declarator
      else
        Role.first(:name => name) || raise(NotFound, "Unkown role :#{name}")
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
    
    # Loads a set of roles from their symbol equivalents
    #
    # @returns the role objects
    def to_roles(*role_names)
      # load a series of mixed roles and symbols
      load_roles = role_names.find_all { |r| r.is_a?(Symbol) }
      result = (role_names - load_roles) | Role.all(:name.in => load_roles)
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
        r = Role.first(:name => name) || Role.new(:name => name)       # delay saving since dm-is-nested-set sets parent
        r.granted_by = self.state
        r.parent     ||= self.state
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