class Role
  include DataMapper::Resource

  property :id,                         Serial
  property :name,                       String,   :nullable => false, :unique => true
  property :title,                      String
  
  property :created_at,                 DateTime
  property :updated_at,                 DateTime
  
  has n, :memberships
  
  # granting
  
  property   :granted_by, Integer
  belongs_to :granted_by, :class_name => self.name, :child_key => [:granted_by]
  has n,     :grants,     :class_name => self.name, :child_key => [:granted_by]

  property   :reviewed_by, Integer
  belongs_to :reviewed_by, :class_name => 'User', :child_key => [:reviewed_by]
  
  is :nested_set
  
  # TODO.  should validate that user in reviewed_by is a member of role in granted_by
  
  # @returns true if this role implies any of the provided ones
  def implies?(*others)
    others = others.to_roles
    others.any? { |r| (lft..rgt).include?(r.lft) }
  end
  
  def expand_grants
    Role.self_and_descendants(*grants)
  end
  
  def to_role
    self
  end
  
  class << self
    def self_and_descendants(*roles)
      spans = roles.map { |r| (r.lft)..(r.rgt) }
      spans = spans.map{ |s| s.to_a }.flatten.uniq        # can be erased once DM suports ranges in arrays
      Role.all(:lft => spans)
    end
  end
  
end

class Symbol
  def to_role
    is_a?(Role) ? self : Role.first(:name => self)
  end
end

class Array
  def to_roles
    load_roles = find_all { |r| r.is_a?(Symbol) }
    (self - load_roles) | Role.all(:name.in => load_roles)
  end
end