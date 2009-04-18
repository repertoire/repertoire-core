# Test data fixtures for running Repertoire core via 'slice' runtime

sue = User.new(:email => 'lorpgui@yahoo.com', :first_name => 'Suzy', :last_name => 'Johnson', :shortname => 'sue')
sue.password = sue.password_confirmation = 'sssss'
sue.save!
sue.activate

nick = User.new(:email => 'guilorp@yahoo.com', :first_name => 'Nick', :last_name => 'Sorrelson', :shortname => 'nick')
nick.password = nick.password_confirmation = 'nnnnn'
nick.save!
nick.activate

joe = User.new(:email => 'orpguil@yahoo.com', :first_name => 'Joe', :last_name => 'Thomason', :shortname => 'joe')
joe.password = joe.password_confirmation = 'jjjjj'
joe.save!
joe.activate

tim = User.new(:email => 'rpguilo@yahoo.com', :first_name => 'Tim', :last_name => 'Timson', :shortname => 'tim')
tim.password = tim.password_confirmation = 'ttttt'
tim.save!
tim.activate

# system declarations
Role.declare do
  Role[:admin,            "Hyperstudio Administrator"]
end

# declarations for Media Collaboration project
Role.declare do
  Role[:mda_manager,      "Media Collaboration - Manager"]
  Role[:mda_contributor,  "Media Collaboration - Contributor"]
  Role[:mda_guest,        "Media Collaboration - Guest"]
  
  Role[:admin].
    grants(:mda_manager).
      grants(:mda_contributor).open.
      implies(:mda_guest).open
end

# declarations for Global Symphony project
Role.declare do
  Role[:sym_publisher, "Global Symphonies Project - Publisher"]
  Role[:sym_vetter,    "Global Symphonies Project - Vetter"]
  Role[:sym_writer,    "Global Symphonies Project - Writer"]
  
  Role[:admin].
    grants(:sym_publisher, :sym_vetter).
      implies(:sym_writer).open
end

nick.subscribe(:sym_writer)
Role.grant!(:admin, sue, "Granting you admin privileges for the winter IAP session.  Thanks, Sue - Hyperstudio sysadmin")
m = nick.subscribe(:sym_publisher, "Please let me in!!! I don't really know what publishing is about but have a blog.  Isn't that similar?")
sue.review(m, false, "Hi Nick, please participate for a writing symphonies to get your feet wet and then try again in a couple of months.  Best, Sue")
nick.subscribe(:sym_vetter, "I've been involved writing symphonies for the past three months and would like to participate in the vetting process.  You can see some of my work with the 'andante' tags.")
sue.grant(:mda_manager, nick, "Hi, Nick - you can now use this account to approve contributors for the Media Collaboration Event")

# Log in programmatically
RepertoireCore::Application.class_eval do
  before Proc.new { session.user = tim }
end

# Print out routes for help
Merb::Router.named_routes.each { |n, r| puts "#{n} #{r}" }