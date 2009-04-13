class RepertoireCore::Memberships < RepertoireCore::Application
  
  include Merb::Helpers::DateAndTime
  
    def index(user_id)
      @user                    = User.get(user_id)
      @memberships             = @user.memberships
      @subscription_membership = Membership.new(:user => @user)
      
      display @memberships
    end

    def show(id)
      @membership = Membership.get(id)
      raise NotFound unless @membership
      display @membership
    end

    def new
      only_provides :html
      @membership = Membership.new
      display @membership
    end

    def edit(id)
      only_provides :html
      @membership = Membership.get(id)
      raise NotFound unless @membership
      display @membership
    end

    def create(membership)
      @membership = Membership.new(membership)
      if @membership.save
        redirect resource(@membership), :message => {:notice => "Membership was successfully created"}
      else
        message[:error] = "Membership failed to be created"
        render :new
      end
    end

    def update(id, membership)
      @membership = Membership.get(id)
      raise NotFound unless @membership
      if @membership.update_attributes(membership)
         redirect resource(@membership)
      else
        display @membership, :edit
      end
    end

    def destroy(id)
      @membership = Membership.get(id)
      raise NotFound unless @membership
      if @membership.destroy
        redirect resource(:memberships)
      else
        raise InternalServerError
      end
    end

  end # Memberships