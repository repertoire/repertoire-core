# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{repertoire_core}
  s.version = "0.3.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Christopher York"]
  s.date = %q{2009-10-24}
  s.description = %q{RepertoireCore provides registration and role based authorization to Repertoire projects}
  s.email = %q{yorkc@mit.edu}
  s.extra_rdoc_files = ["README", "LICENSE", "TODO", "INSTALL"]
  s.files = ["LICENSE", "README", "Rakefile", "TODO", "lib/repertoire_core", "lib/repertoire_core/exceptions.rb", "lib/repertoire_core/merbtasks.rb", "lib/repertoire_core/mixins", "lib/repertoire_core/mixins/authorization_helper.rb", "lib/repertoire_core/mixins/dm", "lib/repertoire_core/mixins/dm/resource_mixin.rb", "lib/repertoire_core/mixins/user_authorization_mixin.rb", "lib/repertoire_core/mixins/user_mixin.rb", "lib/repertoire_core/mixins/user_properties_mixin.rb", "lib/repertoire_core/slicetasks.rb", "lib/repertoire_core/spectasks.rb", "lib/repertoire_core/whois_helper.rb", "lib/repertoire_core.rb", "spec/controllers", "spec/controllers/authorization_helper_spec.rb", "spec/controllers/memberships_spec.rb", "spec/controllers/users_spec.rb", "spec/mailers", "spec/mailers/user_mailer_spec.rb", "spec/models", "spec/models/role_spec.rb", "spec/models/user_spec.rb", "spec/repertoire_core_spec.rb", "spec/spec_helper.rb", "spec/spec_helpers", "spec/spec_helpers/helpers.rb", "spec/spec_helpers/valid_model_hashes.rb", "app/controllers", "app/controllers/application.rb", "app/controllers/memberships.rb", "app/controllers/users.rb", "app/helpers", "app/helpers/application_helper.rb", "app/helpers/memberships_helper.rb", "app/mailers", "app/mailers/user_mailer.rb", "app/mailers/views", "app/mailers/views/layout", "app/mailers/views/layout/core.text.erb", "app/mailers/views/user_mailer", "app/mailers/views/user_mailer/activation.text.erb", "app/mailers/views/user_mailer/approve.text.erb", "app/mailers/views/user_mailer/deny.text.erb", "app/mailers/views/user_mailer/grant.text.erb", "app/mailers/views/user_mailer/password_reset_key.text.erb", "app/mailers/views/user_mailer/request.text.erb", "app/mailers/views/user_mailer/signup.text.erb", "app/models", "app/models/membership.rb", "app/models/role.rb", "app/views", "app/views/_memberships_table.html.erb", "app/views/_user_detail.html.erb", "app/views/exceptions", "app/views/exceptions/unauthenticated.html.erb", "app/views/layout", "app/views/layout/core.html.erb", "app/views/memberships", "app/views/memberships/edit.html.erb", "app/views/memberships/grant.html.erb", "app/views/memberships/index.html.erb", "app/views/memberships/subscribe.html.erb", "app/views/README", "app/views/users", "app/views/users/edit.html.erb", "app/views/users/forgot_password.html.erb", "app/views/users/index.html.erb", "app/views/users/new.html.erb", "app/views/users/requests.html.erb", "app/views/users/reset_password.html.erb", "public/images", "public/images/gravatar.png", "public/images/hyperstudio.jpg", "public/javascripts", "public/javascripts/lib", "public/javascripts/lib/jquery.easing.js", "public/javascripts/lib/jquery.form.js", "public/javascripts/lib/jquery.js", "public/javascripts/lib/jquery.suggest.js", "public/javascripts/lib/jquery.tablesorter.patched.js", "public/javascripts/lib/jquery.tooltip.js", "public/javascripts/lib/jquery.ui.all.js", "public/javascripts/lib/README", "public/javascripts/README", "public/javascripts/rep.ajax-validate.js", "public/stylesheets", "public/stylesheets/core.css", "public/stylesheets/images", "public/stylesheets/images/green_check.png", "public/stylesheets/images/red_cross.png", "public/stylesheets/images/spinner_sm.gif", "public/stylesheets/lib", "public/stylesheets/lib/images", "public/stylesheets/lib/images/ui-bg_flat_0_aaaaaa_40x100.png", "public/stylesheets/lib/images/ui-bg_flat_75_ffffff_40x100.png", "public/stylesheets/lib/images/ui-bg_glass_55_fbf9ee_1x400.png", "public/stylesheets/lib/images/ui-bg_glass_65_ffffff_1x400.png", "public/stylesheets/lib/images/ui-bg_glass_75_dadada_1x400.png", "public/stylesheets/lib/images/ui-bg_glass_75_e6e6e6_1x400.png", "public/stylesheets/lib/images/ui-bg_glass_95_fef1ec_1x400.png", "public/stylesheets/lib/images/ui-bg_highlight-soft_75_cccccc_1x100.png", "public/stylesheets/lib/images/ui-icons_222222_256x240.png", "public/stylesheets/lib/images/ui-icons_2e83ff_256x240.png", "public/stylesheets/lib/images/ui-icons_454545_256x240.png", "public/stylesheets/lib/images/ui-icons_888888_256x240.png", "public/stylesheets/lib/images/ui-icons_cd0a0a_256x240.png", "public/stylesheets/lib/jquery-ui.css", "public/stylesheets/lib/jquery.suggest.css", "public/stylesheets/lib/jquery.tablesorter.blue", "public/stylesheets/lib/jquery.tablesorter.blue/asc.gif", "public/stylesheets/lib/jquery.tablesorter.blue/bg.gif", "public/stylesheets/lib/jquery.tablesorter.blue/desc.gif", "public/stylesheets/lib/jquery.tablesorter.blue/style.css", "public/stylesheets/lib/README", "public/stylesheets/membership.css", "public/stylesheets/README", "public/stylesheets/rep.ajax-validate.css", "stubs/app", "stubs/app/controllers", "stubs/app/controllers/users.rb", "INSTALL"]
  s.homepage = %q{http://hyperstudio.mit.edu/repertoire}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{merb}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{RepertoireCore provides registration and role based authorization to Repertoire projects}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<merb-mailer>, [">= 1.1"])
      s.add_runtime_dependency(%q<merb-assets>, [">= 1.1"])
      s.add_runtime_dependency(%q<merb-action-args>, [">= 1.1"])
      s.add_runtime_dependency(%q<merb-auth-core>, [">= 1.1"])
      s.add_runtime_dependency(%q<merb-auth-more>, [">= 1.1"])
      s.add_runtime_dependency(%q<merb-auth-slice-password>, [">= 1.1"])
      s.add_runtime_dependency(%q<merb-helpers>, [">= 1.1"])
      s.add_runtime_dependency(%q<merb-slices>, [">= 1.1"])
      s.add_runtime_dependency(%q<dm-core>, [">= 0.9.11"])
      s.add_runtime_dependency(%q<dm-constraints>, [">= 0.9.11"])
      s.add_runtime_dependency(%q<dm-validations>, [">= 0.9.11"])
      s.add_runtime_dependency(%q<dm-timestamps>, [">= 0.9.11"])
      s.add_runtime_dependency(%q<dm-aggregates>, [">= 0.9.11"])
      s.add_runtime_dependency(%q<dm-is-nested_set>, [">= 0.9.11"])
      s.add_runtime_dependency(%q<dm-is-list>, [">= 0.9.11"])
      s.add_runtime_dependency(%q<whois>, [">= 0.4.2"])
      s.add_runtime_dependency(%q<tlsmail>, [">= 0.0.1"])
    else
      s.add_dependency(%q<merb-mailer>, [">= 1.1"])
      s.add_dependency(%q<merb-assets>, [">= 1.1"])
      s.add_dependency(%q<merb-action-args>, [">= 1.1"])
      s.add_dependency(%q<merb-auth-core>, [">= 1.1"])
      s.add_dependency(%q<merb-auth-more>, [">= 1.1"])
      s.add_dependency(%q<merb-auth-slice-password>, [">= 1.1"])
      s.add_dependency(%q<merb-helpers>, [">= 1.1"])
      s.add_dependency(%q<merb-slices>, [">= 1.1"])
      s.add_dependency(%q<dm-core>, [">= 0.9.11"])
      s.add_dependency(%q<dm-constraints>, [">= 0.9.11"])
      s.add_dependency(%q<dm-validations>, [">= 0.9.11"])
      s.add_dependency(%q<dm-timestamps>, [">= 0.9.11"])
      s.add_dependency(%q<dm-aggregates>, [">= 0.9.11"])
      s.add_dependency(%q<dm-is-nested_set>, [">= 0.9.11"])
      s.add_dependency(%q<dm-is-list>, [">= 0.9.11"])
      s.add_dependency(%q<whois>, [">= 0.4.2"])
      s.add_dependency(%q<tlsmail>, [">= 0.0.1"])
    end
  else
    s.add_dependency(%q<merb-mailer>, [">= 1.1"])
    s.add_dependency(%q<merb-assets>, [">= 1.1"])
    s.add_dependency(%q<merb-action-args>, [">= 1.1"])
    s.add_dependency(%q<merb-auth-core>, [">= 1.1"])
    s.add_dependency(%q<merb-auth-more>, [">= 1.1"])
    s.add_dependency(%q<merb-auth-slice-password>, [">= 1.1"])
    s.add_dependency(%q<merb-helpers>, [">= 1.1"])
    s.add_dependency(%q<merb-slices>, [">= 1.1"])
    s.add_dependency(%q<dm-core>, [">= 0.9.11"])
    s.add_dependency(%q<dm-constraints>, [">= 0.9.11"])
    s.add_dependency(%q<dm-validations>, [">= 0.9.11"])
    s.add_dependency(%q<dm-timestamps>, [">= 0.9.11"])
    s.add_dependency(%q<dm-aggregates>, [">= 0.9.11"])
    s.add_dependency(%q<dm-is-nested_set>, [">= 0.9.11"])
    s.add_dependency(%q<dm-is-list>, [">= 0.9.11"])
    s.add_dependency(%q<whois>, [">= 0.4.2"])
    s.add_dependency(%q<tlsmail>, [">= 0.0.1"])
  end
end
