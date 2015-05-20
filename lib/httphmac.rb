require 'digest'
require 'digest/hmac'
require 'securerandom'
require 'uri'

module Acquia
	class HTTPHmac
	  VERSION = '2.0'

		def initialize(realm, secret)
		  @realm = realm
		  @secret = secret
		end

		def prepare_request(http_method, host, id, path_info= '/', query_string = '', body = '', content_type = '')
		  body_hash = nil
		  if body.length
  		  body_hash = Digest::SHA256.base64digest(body)
  		end
  		http_method = http_method.upcase
		  base_string_parts = [http_method, host, path_info]
		  timestamp = "%0.6f" % Time.now.to_f
		  nonce = SecureRandom.uuid
		  base_string_parts << "id=#{URI.escape(id)}&nonce=#{nonce}&realm=#{URI.escape(@realm)}&timestamp=#{timestamp}&version=#{VERSION}"
      if ['GET', 'HEAD'].include?(http_method)
        unless query_string.empty?
          base_string_parts << normalize_query(query_string)
        end
		  elsif !body.empty?
		    # Body hash
  		  base_string_parts << Digest::SHA256.base64digest(body)
  		  base_string_parts << content_type.downcase
  		end
  		base_string = base_string_parts.join("\n")

		  authorization = []
		  authorization << "acquia-http-hmac realm=\"#{@realm}\""
		  authorization << "id=\"#{id}\""
		  authorization << "timestamp=\"#{timestamp}\""
		  authorization << "nonce=\"#{nonce}\""
		  authorization << "version=#{VERSION}"
		  authorization << "signature=\"#{signature(base_string)}\""
      authorization.join(',')
		end

		def valid_request?(http_method, host, path_info, authorization_header, query_string = '', body = '', content_type = '')
		end

		def normalize_query(query_string)
		  query_string
		end

		def signature(base_string)
		  Digest::HMAC.base64digest(base_string, @secret, Digest::SHA256)
		end
	end
end
