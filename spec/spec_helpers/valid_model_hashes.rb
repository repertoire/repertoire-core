module ValidModelHashes
  def valid_user_hash
    { :email                  => "#{String.random}@example.com",
      :first_name             => String.random,
      :last_name              => String.random,
      :password               => "sekret",
      :password_confirmation  => "sekret"
    }
  end
end

