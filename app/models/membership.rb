class Membership
  include DataMapper::Resource

  property :id,                         Integer, :serial   => true
  property :user_note,                  Text
  
  property :approved_at,                DateTime
  property :reviewer_id,                Integer
  property :reviewer_note,              Text
  
  property :created_at,                 DateTime
  property :updated_at,                 DateTime
  
  belongs_to :user
  belongs_to :role
  belongs_to :reviewer, :class_name => 'User', :child_key => [:reviewer_id]
  
  #
  # Membership subscription review process
  #
  
  def review(user, approve, message = nil)
    is_bootstrapping = Membership.count == 1
    is_grantable     = user.grantable_roles.any? { |grantable| grantable.implies?(role) }
    raise "#{user.full_name} cannot grant #{role.name}" unless is_grantable || is_bootstrapping
    
    self.approved_at = approve ? Time.now.utc : nil
    self.reviewer = user
    self.reviewer_note = message
    save
    self
  end
  
  def reviewed?
    reviewer != nil
  end
  
  def approved?
    approved_at != nil
  end
  
  def rejected?
    reviewed? && !approved?
  end
  
  #
  # Utility functions
  #

  # membership sorting: by creation date
  def <=>(other)
    created_at <=> other.created_at
  end
  
end
