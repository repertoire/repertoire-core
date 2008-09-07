namespace :slices do
  namespace :repertoire_core do 
    
    # implement this to test for structural/code dependencies
    # like certain directories or availability of other files
    desc "Test for any dependencies"
    task :preflight do
    end
    
    # implement this to perform any database related setup steps
    desc "Migrate the database"
    task :migrate => :merb_env do
      # NOTE.  dependency on merb_env causes merb to load so models available
      
      # TODO.  move this into a migration?
      adapter = DataMapper.repository(:default).adapter
      adapter.execute('SET search_path TO public')              # install into public schema
      
      User.auto_migrate!
      Role.auto_migrate!
      Membership.auto_migrate!
    end
    
  end
end