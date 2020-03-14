# This module contains the client code for Vanilla jsConnect single sign on
# Author:: Todd Burry (mailto:todd@vanillaforums.com)
# Version:: 2.0
# Copyright:: copyright 2008-2017 Vanilla Forums, Inc.
# License http://www.opensource.org/licenses/gpl-2.0.php GPLv2

require 'openssl'
require 'json'
require 'base64'
require 'cgi'

module JsConnect
  VERSION = '2'.freeze
  TIMEOUT = 24 * 60

  def self.error(code, message)
    return { 'error' => code, 'message' => message }
  end

  def self.js_connect_string(user, request = {}, client_id = '', secret = '', secure = true, digest = Digest::MD5)
    error = nil

    timestamp = request['timestamp'].to_i
    current_timestamp = JsConnect.timestamp

    if secure
      # Make sure the request coming in is signed properly
      if !request['v']
        error = JsConnect.error('invalid_request', 'Missing the v parameter.')
      elsif request['v'] != VERSION
        error = JsConnect.error('invalid_request', "Unsupported version #{request['v']}.")
      elsif !request['client_id']
        error = JsConnect.error('invalid_request', 'Missing the client_id parameter.')
      elsif request['client_id'] != client_id
        error = JsConnect.error('invalid_client', "Unknown client #{request['client_id']}.")
      elsif request['timestamp'].nil? && request['sig'].nil?
        error = if user && !user.empty?
                  { 'name' => user['name'], 'photourl' => user['photourl'] }
                else
                  { 'name' => '', 'photourl' => '' }
                end
      elsif request['timestamp'].nil?
        error = JsConnect.error('invalid_request', 'The timestamp is missing or invalid.')
      elsif !request['sig']
        error = JsConnect.error('invalid_request', 'Missing sig parameter.')
      elsif (current_timestamp - timestamp).abs > TIMEOUT
        error = JsConnect.error('invalid_request', 'The timestamp is invalid.')
      elsif !request['nonce']
        error = JsConnect.error('invalid_request', 'Missing nonce parameter.')
      elsif !request['ip']
        error = JsConnect.error('invalid_request', 'Missing ip parameter.')
      else
        # Make sure the signature checks out.
        sig = digest.hexdigest(request['ip'] + request['nonce'] + timestamp.to_s + secret)
        error = JsConnect.error('access_denied', 'Signature invalid.') if sig != request['sig']
      end
    end

    if error
      result = error
    elsif user && !user.empty?
      result = user.clone
      result['ip'] = request['ip']
      result['nonce'] = request['nonce']
      JsConnect.sign_js_connect(result, client_id, secret, true, digest)
      result['v'] = VERSION
    else
      result = { 'name' => '', 'photourl' => '' }
    end

    json = ActiveSupport::JSON.encode(result)
    request['callback'] = CGI.escapeHTML(request['callback'])

    return "#{request['callback']}(#{json});" if request['callback']

    return json
  end

  def self.sign_js_connect(data, client_id, secret, set_data = false, digest = Digest::MD5)
    # Build the signature string. This is essentially a querystring representation of data, sorted by key
    keys = data.keys.sort { |a, b| a.downcase <=> b.downcase }

    sig_str = ''

    keys.each do |key|
      sig_str += '&' unless sig_str.empty?

      value = data[key]
      sig_str += CGI.escape(key) + '=' + CGI.escape(value.to_s)
    end

    signature = digest.hexdigest(sig_str + secret)

    if set_data
      data['clientid'] = client_id
      data['sig'] = signature
    end

    return signature
  end

  def self.timestamp
    return Time.now.to_i
  end

  # Public: Generate an SSO string suitable for passing in the url for embedded SSO.
  #
  # user      - The user to sso.
  # client_id - Your client ID.
  # secret    - Your secret.
  #
  # Examples
  #
  #   JsConnect.getSSOString({ name => "John Ruby", ... }, "1234", "1234")
  #   # => "eyJ1bmlx... 0fe8d102... 1402067133 hmacsha1"
  #
  # Returns the generated SSO string.
  def self.sso_string(user, client_id, secret)
    user['client_id'] = client_id unless user['client_id']

    string = Base64.strict_encode64(JSON.generate(user))
    timestamp = JsConnect.timestamp
    digest = OpenSSL::Digest::Digest.new('sha1')
    hash = OpenSSL::HMAC.hexdigest(digest, secret, "#{string} #{timestamp}")

    result = "#{string} #{hash} #{timestamp} hmacsha1"

    return result
  end
end
