module Merb
  module RepertoireCore
    module ApplicationHelper

      # @return a url to identify the given user's profile photo
      def gravatar_image_url(email, size=40)
        default_gravatar_uri = request.protocol + "://#{request.host}#{Merb::Config[:path_prefix]}/images/rep.core/gravatar.png"
        return default_gravatar_uri if email.nil?
        
        email_md5 = Digest::MD5.hexdigest(email)
        encoded_uri = URI.escape(default_gravatar_uri, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        "http://www.gravatar.com/avatar.php?gravatar_id=#{email_md5}&default=#{encoded_uri}&size=#{size}" 
      end

      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def image_path(*segments)
        public_path_for(:image, *segments)
      end
      
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def javascript_path(*segments)
        public_path_for(:javascript, *segments)
      end
      
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def stylesheet_path(*segments)
        public_path_for(:stylesheet, *segments)
      end
      
      # Construct a path relative to the public directory
      # 
      # @param <Symbol> The type of component.
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def public_path_for(type, *segments)
        ::RepertoireCore.public_path_for(type, *segments)
      end
      
      # Construct an app-level path.
      # 
      # @param <Symbol> The type of component.
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path within the host application, with added segments.
      def app_path_for(type, *segments)
        ::RepertoireCore.app_path_for(type, *segments)
      end
      
      # Construct a slice-level path.
      # 
      # @param <Symbol> The type of component.
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path within the slice source (Gem), with added segments.
      def slice_path_for(type, *segments)
        ::RepertoireCore.slice_path_for(type, *segments)
      end
    end
  end
end