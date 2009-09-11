require 'whois'

module RepertoireCore
  
  # Ecapsulate access to the whois domain lookup service
  class WhoisHelper

    def lookup!(user)
      begin 
        domain = user.email.match(/@(.*)$/)[1].downcase
        
        client = Whois::Client.new
        client.timeout = 3
        result = client.query(domain)
        
        props = whois_to_hash(result)
      
        user.institution      = props['OrgName']
        user.institution_code = props['OrgID']
        return true

      rescue Whois::WhoisException => e
        Merb.logger.warn(e)
        return false
      end
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