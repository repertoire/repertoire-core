
Merb::Router.prepare do
 slice(:merb_auth_slice_password, :name_prefix => nil, :path_prefix => "")
 slice(:repertoire_core, :name_prefix => nil, :path_prefix => "")
end