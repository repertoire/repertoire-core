class RepertoireCore::Application < Merb::Controller

  controller_for_slice
  
  # TODO.  why doesn't this exist in merb-slices?
  def absolute_slice_url(slice_name, *args)  
    request.protocol + "://" + request.host + slice_url(slice_name, *args)
  end
  
end
