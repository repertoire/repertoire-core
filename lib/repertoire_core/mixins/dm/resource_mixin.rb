module DataMapper
  module Resource
    
    # For use with incremental ajax form validation (see public/javascripts/rep.ajax-validate.js)
    # Convenience method to wrap DataMapper errors object in a hash with keys formatted as in merb_helper forms
    def errors_as_params(name = nil)
      name ||= self.class.to_s.snake_case
      errors.to_hash.inject({}) { |h, (k,v)| h["#{name}[#{k}]"] = v; h }
    end
    
  end
end