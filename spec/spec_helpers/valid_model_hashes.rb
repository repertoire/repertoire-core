module ValidModelHashes
  def valid_user_hash
    { :email                  => "#{String.random}@mit.edu",
      :first_name             => String.random,
      :last_name              => String.random,
      :shortname              => String.random,
      :password               => "77MassAve",
      :password_confirmation  => "77MassAve"
    }
  end
end

