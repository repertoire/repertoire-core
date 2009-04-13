class Membership
  include DataMapper::Resource

  property :id,                         Integer, :serial   => true

  # user's subscription request
  belongs_to :user
  belongs_to :role
  property   :user_note,                Text

  # reviewer's decision
  belongs_to :reviewer, :class_name => 'User', :child_key => [:reviewer_id]
  property :reviewer_note,              Text  
  property :approved_at,                DateTime
  
  # administrative data
  property :created_at,                 DateTime
  property :updated_at,                 DateTime
  
  # for cases where membership is open, approve automatically
  before :save do
    self.attempt_review(user, true) unless reviewed?
  end
  
  #
  # Membership status
  #
  
  def reviewed?
    !reviewer.nil? || !approved_at.nil?
  end
  
  def approved?
    !approved_at.nil?
  end
  
  def rejected?
    reviewed? && !approved?
  end

  def status
    case
    when approved? then :approved
    when rejected? then :rejected
    else :pending
    end
  end

  #
  # Membership subscription review process
  #

  # Attempt to review the membership, raising an exception if review is not permitted
  def review(reviewer, approve, message=nil)
    unless attempt_review(reviewer, approve, message).reviewed?
      raise RepertoireCore::Forbidden, "Insufficient permissions to review this membership request"
    end
    self
  end

  # Attempt to review the membership, either approving or denying
  #
  # Returns the updated membership - use membership.attempt_review(user, true).reviewed? to check success
  def attempt_review(reviewer, approve, message = nil)
    if role.open_membership? || reviewer.can_grant?(role)
      self.approved_at   = approve ? Time.now.utc : nil
      self.reviewer      = reviewer
      self.reviewer_note = message
      self.save
      self.reload
    else
      self
    end
  end
  
  # Provide a list of related membership requests, as context for review decisions
  #
  # Specifically, returns all membership requests by the same user, for roles that encompass,
  # equal, or are encompassed by this one.
  def related_requests
    related_roles = self.role.ancestors | self.role.self_and_descendants
    related_roles.memberships(:user_id => self.user.id, :id.not => self.id)
  end
end
