# message_media_messages
#
# This file was automatically generated by APIMATIC v2.0
# ( https://apimatic.io ).

require 'base64'

module MessageMediaMessages
  # Utility class for basic authorization.
  class AuthManager
    # Add authentication to the request.
    # @param [HttpRequest] The HttpRequest object to which authentication will
    # be added.
    # @param [String] The url of the request.
    # @param [String] The body of the request. None for GET requests.
    def self.apply(http_request, url, body = nil)
      if Configuration.hmac_auth_user_name.nil? ||
         Configuration.hmac_auth_password.nil?
        AuthManager.apply_basic_auth(http_request)
      else
        AuthManager.apply_hmac_auth(http_request, url, body)
      end
    end

    # Add basic authentication to the request.
    # @param [HttpRequest] The HttpRequest object to which authentication will
    # be added.
    def self.apply_basic_auth(http_request)
      username = Configuration.basic_auth_user_name
      password = Configuration.basic_auth_password
      value = Base64.strict_encode64("#{username}:#{password}")
      header_value = "Basic #{value}"
      http_request.headers['Authorization'] = header_value
    end

    # Add hmac authentication to the request.
    # @param [HttpRequest] The HttpRequest object to which authentication will
    # be added.
    # @param [String] The url of the request.
    # @param [String] The body of the request. None for GET requests.
    def self.apply_hmac_auth(http_request, url, body)
      username = Configuration.hmac_auth_user_name

      content_signature = ''
      content_header = ''

      now = Time.now.utc.strftime('%a, %d %b %Y %H:%M:%S GMT')

      date_header = now

      request_type = 'GET'

      unless body.nil?
        request_type = 'POST'

        md5 = Digest::MD5.new
        md5.update(body)

        content_hash = md5.hexdigest
        content_signature = "x-Content-MD5: #{content_hash}\n"
        content_header = 'x-Content-MD5 '
        http_request.headers['x-Content-MD5'] = content_hash
      end

      http_request.headers['date'] = date_header

      hmac_signature = AuthManager.create_signature(date_header,
                                                    content_signature, url,
                                                    request_type)

      joined = "username=\"#{username}\", algorithm=\"hmac-sha1\", " \
               "headers=\"date #{content_header}request-line\", " \
               "signature=\"#{hmac_signature}\""
      header_value = "hmac #{joined}"
      http_request.headers['Authorization'] = header_value
    end

    def self.create_signature(date, content_signature, url, request_type)
      signing_string = "date: #{date}\n#{content_signature}#{request_type} " \
                       "#{url} HTTP/1.1"
      hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'),
                                  Configuration.hmac_auth_password.encode(
                                    Encoding::UTF_8
                                  ),
                                  signing_string.encode(Encoding::UTF_8))

      Base64.encode64(hmac).chomp
    end
  end
end
