class RepertoireCore::Application < Merb::Controller

  before :authenticate

  controller_for_slice
  
end
