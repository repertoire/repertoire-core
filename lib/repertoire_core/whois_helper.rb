require 'whois'

module RepertoireCore
  module WhoisHelper
    
    def lookup_domain(email)
      domain = email.match(/@(.*)$/)[1].downcase
      result = Whois::Whois.new(domain).search_whois
      whois_to_hash(result)
    end
  
    private
    def whois_to_hash(ret)
      props = {}
      ret.scan(/^(\w+):\s*(.*?)\s*$/s).each do |k, v|
        if props[k]
          props[k] = [props[k], v].flatten if props[k]
        else
          props[k] = v
        end
      end
      props
    end
    
  end
end