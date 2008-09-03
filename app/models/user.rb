class User
  include DataMapper::Resource

  attr_accessor :password, :password_confirmation

  property :id,                         Integer,  :serial   => true
  property :last_name,                  String,   :nullable => false
  property :first_name,                 String,   :nullable => false
  property :bio,                        Text
  
  property :email,                      String,   :nullable => false, :unique => true
  property :institution,                String
  property :institution_code,           String
  
  property :activated_at,               DateTime
  property :activation_code,            String

  property :created_at,                 DateTime
  property :updated_at,                 DateTime
  property :crypted_password,           String
  property :salt,                       String
  property :remember_token_expires_at,  DateTime
  property :remember_token,             String
  property :password_reset_key,         String, :writer => :protected
  
  # has n, :emails              # :dependent => :destroy
  has n, :memberships
  has n, :reviews, :class_name => 'Role', :child_key => [:reviewed_by]

  validates_present             :password, :if => proc{|m| m.password_required?}
  validates_is_confirmed        :password, :if => proc{|m| m.password_required?}

  before :save,   :encrypt_password
  before :create, :make_activation_code
  
  # @returns the set of approved roles for this user
  def roles
    memberships.all(:approved_at.not => nil).role
  end
  
  #
  # Registration and activation
  #

  # Activate a user email programmatically, sending confirmation
  # TODO.  move email to controller
  def activate
    set_activated_data!
    self.save
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  # returns false if the user has registered but not activated
  def activated?
   return false if self.new_record?
   !! activation_code.nil?
  end

  # Creates and returns a new activation code
  def make_activation_code
    self.activation_code = self.class.make_key
  end

  #
  # User authentication
  #

  # Encrypts the given string with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  # Sets user salt and encrypts user password with it
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  # Checks if user can be authenticated using given password
  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  # For user profile forms, returns true if user MUST supply the password field
  def password_required?
    crypted_password.blank? || !password.blank?
  end
  
  #
  # Authorization
  #
  # NOTE.  You can use security methods other than RBAC:
  #        put the appropriate filter in your controller.
  #        For an example, see has_institution?
  #
  
  # Check whether user has any of the supplied roles.  Use this in a filter to control access.
  def has_role?(*role_names)
    match_roles = role_names.to_roles
    roles.any? { |r| r.implies?(*match_roles) }
  end
  
  # Check whether user is affiliated with any of the supplied insitutitons (by code).  Use this in a filter to control access.
  def has_institution(*insitution_codes)
    insitution_codes.include?(self.institution_code)
  end
  
  # returns all roles this user could subscribe to 
  def subscribable_roles
    # list of all parents of user's roles that are subscribable
    user_parent_role_ids = roles.map { |r| r.parent.id }
    
    open_roles     = Role.leaves.all(:reviewed_by.not => nil)
    stepwise_roles = Role.all(:reviewed_by.not => nil, :id.in => user_parent_role_ids)
    
    (open_roles | stepwise_roles).uniq
  end

  # Subscribe user to a new role (passed as symbol or object).
  def subscribe(role_name, message=nil)
    role = role_name.to_role
    raise "#{role_name} is not subscribable" unless subscribable_roles.include?(role)
    m = Membership.create(:user => user, :role => role).save!
    save
    reload
  end

  # returns the roles this user can grant
  def grantable_roles
    user_role_ids = roles.map { |r| r.id }
    Role.all(:granted_by.in => user_role_ids)
  end

  # current user grants role to another user.  raises an exception if this is disallowed.
  def grant(role_name, user, message=nil)
    role = role_name.to_role
    user.transaction do |t|
      membership = Membership.create(:user => user, :role => role).save!
      membership.review(self, true, message) unless membership.reviewed?
      user.save
      user.reload
    end
    user
  end

  #
  # Remember me tokens
  #

  # Check if remember token available and still valid
  def remember_token?
    remember_token_expires_at && DateTime.now < DateTime.parse(remember_token_expires_at.to_s)
  end

  # Sets the remember token to be valid until given time
  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save
  end

  # Sets the remember token to be valid for given number of seconds
  def remember_me_for(time)
    time = time / Merb::Const::DAY
    remember_me_until (DateTime.now + time)
  end

  # These create and unset the fields required for remembering users between browser closes
  # Default of 2 weeks 
  def remember_me
    remember_me_for (Merb::Const::WEEK * 2)
  end

  # Erases remember me token
  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    self.save
  end
  
  #
  # Forgotten password support
  #

  def forgot_password! 
    # Must be a unique password key before it goes in the database
    pwreset_key_success = false
    until pwreset_key_success
      self.password_reset_key = User.make_key
      self.save
      pwreset_key_success = self.errors.on(:password_reset_key).nil? ? true : false 
    end
  end

  def forgotten_password?
    self.password_reset_key != nil
  end

  def clear_forgotten_password!
    self.password_reset_key = nil
    self.save
  end
  
  #
  # Utility functions on instance
  #
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  #
  # Utility functions
  #

  class << self
    # Encrypts some data with the salt.
    def encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end

    # Authenticates a user by their email field and unencrypted password.  Returns the user or nil.
    def authenticate(email, password)
      user = User.first(:email => email, :activated_at.not => nil)
      
      return                         unless user && user.authenticated?(password)
      user.clear_forgotten_password! if user.forgotten_password?
      user
    end

    # Creates and returns a unique hexdigested key
    def make_key
      Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end
    
  end
  
  private
  def set_activated_data!
    @activated = true
    self.activated_at = DateTime.now
    self.activation_code = nil

    true
  end
end