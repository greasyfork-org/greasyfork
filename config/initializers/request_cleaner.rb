# For ID parameter, clean instead of raise.
module ActionDispatch
  class Request
    class Utils
      def self.check_param_encoding(params)
        case params
        when Array
          params.each { |element| check_param_encoding(element) }
        when Hash
          #params.each_value { |value| check_param_encoding(value) }
          params.each{|k, v| 
            if k == :id
              params[k] = ActiveSupport::Multibyte::Unicode.tidy_bytes(v) 
            else
              check_param_encoding(v)
            end
          }
        when String
          unless params.valid_encoding?
            # Raise Rack::Utils::InvalidParameterError for consistency with Rack.
            # ActionDispatch::Request#GET will re-raise as a BadRequest error.
            raise Rack::Utils::InvalidParameterError, "Non UTF-8 value: #{params}"
          end
        end
      end
    end
  end
end
