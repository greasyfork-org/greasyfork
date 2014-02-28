# This module contains the client code for Vanilla jsConnect single sign on
# Author:: Todd Burry (mailto:todd@vanillaforums.com)
# Version:: 1.0b
# Copyright:: Copyright 2008, 2009 Vanilla Forums Inc.
# License http://www.opensource.org/licenses/gpl-2.0.php GPLv2

module JsConnect
    def JsConnect.error(code, message)
      return {"error" => code, "message" => message}
    end
    
    def JsConnect.getJsConnectString(user, request = {}, client_id = "", secret = "", secure = true)
      error = nil
      
      timestamp = request["timestamp"].to_i
      current_timestamp = JsConnect.timestamp
      
      if secure
        # Make sure the request coming in is signed properly
        
        if !request['client_id']
          error = JsConnect.error('invalid_request', 'The client_id parameter is missing.')
        elsif request['client_id'] != client_id
          error = JsConnect.error('invalid_client', "Unknown client #{request['client_id']}.")
        elsif request['timestamp'].nil? and request['signature'].nil?
          if user and !user.empty?
            error = {'name' => user['name'], 'photourl' => user['photourl']}
          else
            error = {'name' => '', 'photourl' => ''}
          end
        elsif request['timestamp'].nil?
          error = JsConnect.error('invalid_request', 'The timestamp is missing or invalid.')
        elsif !request['signature']
          error = JsConnect.error('invalid_request', 'The signature is missing.')
        elsif (current_timestamp - timestamp).abs > 30 * 60
          error = JsConnect.error('invalid_request', 'The timestamp is invalid.')
        else
          # Make sure the timestamp's signature checks out.
          timestamp_sig = Digest::MD5.hexdigest(timestamp.to_s + secret)
          if timestamp_sig != request['signature']
            error = JsConnect.error('access_denied', 'Signature invalid.')
          end
        end
      end
      
      if error
        result = error
      elsif user and !user.empty?
        result = user.clone
        JsConnect.signJsConnect(result, client_id, secret, true)
      else
        result = {"name" => "", "photourl" => ""}
      end
      
      json = ActiveSupport::JSON.encode(result);
      if request["callback"]
        return "#{request["callback"]}(#{json});"
      else
        return json
      end
    end
    
   def JsConnect.signJsConnect(data, client_id, secret, set_data = false)
     # Build the signature string. This is essentially a querystring representation of data, sorted by key
     keys = data.keys.sort { |a,b| a.downcase <=> b.downcase }
     
     sig_str = ""
     
     keys.each do |key|
      if sig_str.length > 0
        sig_str += "&"
      end
      
       value = data[key]
       sig_str += CGI.escape(key) + "=" + CGI.escape(value)
     end
     
     signature = Digest::MD5.hexdigest(sig_str + secret);
     
     if set_data
       data["clientid"] = client_id
       data["signature"] = signature
     end
     return signature
   end
   
   def JsConnect.timestamp
     return Time.now.to_i
   end
end
