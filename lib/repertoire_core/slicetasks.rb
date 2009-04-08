namespace :slices do
  namespace :repertoire_core do 
    
    # implement this to test for structural/code dependencies
    # like certain directories or availability of other files
    desc "Test for any dependencies"
    task :preflight do
    end
    
    # convenience task to over-write Merb's login page with our own
    desc "Install login page"
    task :freeze_login do
      
    end
    
    # implement this to perform any database related setup steps
    desc "Migrate the database"
    task :migrate => :merb_env do
      # NOTE.  dependency on merb_env causes merb to load so models available
      #        however, we connnect as 'postgres' just for the purposes of creating the 
      #        model tables and granting access to the project
      default_uri = DataMapper.repository(:default).adapter.uri
      core_uri    = DataMapper.repository(:core).adapter.uri
      project     = default_uri.user
      
      Merb.logger.info "Detected your Hyperstudio project abbreviation is '#{project}'"

      # error check database configuration
      case
      when default_uri.path != core_uri.path then raise "Repertoire and project-level tables should be in the same database"
      when default_uri.user == 'postgres'    then raise "Project-level tables should have their own schema and user for access"
      when default_uri.user == core_uri.user then raise "Repertoire core tables should not be stored in the project-level database schema"
      end

      # create repertoire tables transactionally in the public schema      
      repository(:core) do
        DataMapper::Transaction.new do |txn|
          core_models = [ User, Role, Membership ]
        
          Merb.logger.info "Migrating Repertoire Core models into #{core_uri}"
          core_models.each do |m| 
            m.auto_migrate!
            [ "ALTER TABLE #{m.storage_name} OWNER TO #{core_uri.user}",
              "ALTER SEQUENCE #{m.storage_name}_id_seq OWNED BY #{m.storage_name}.id",
              "GRANT ALL ON #{m.storage_name} TO #{project}",
              "GRANT ALL ON #{m.storage_name}_id_seq TO #{project}" ].each { |stmt| repository(:core).adapter.execute(stmt) }
          end
        end
      end
    end
    
  end
end