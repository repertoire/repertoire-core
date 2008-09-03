class Email
  
  # NOTE.  this class is not currently used
  
  include DataMapper::Resource

  property :id,                         Integer,  :serial => true
  property :address,                    String,   :nullable => false, :unique => true
  property :activated_at,               DateTime
  property :activation_code,            String
  
  property :institution_code,           String
  property :institution,                String
  
  belongs_to :user
  
  validates_format                      :email, :as => :email_address
  
  is :list, :scope => [:user_id]
  
  before :create, :make_activation_code

  # Activate a user email programmatically, sending confirmation
  # TODO.  move email to controller
  def activate
    set_activated_data!
    set_institution!
    self.save

    # send mail for activation   TODO. move this to a controller
    send_activation_notification
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

  private
  def set_activated_data!
    @activated = true
    self.activated_at = DateTime.now
    self.activation_code = nil

    true
  end
  
  def set_institution!
    begin
      props = WhoisHelper.lookup(address)
      self.institution = props['OrgName']
    rescue Exception => e
      Merb.logger.warn(e)
      self.instiuttion = nil
    end
  end
  
end