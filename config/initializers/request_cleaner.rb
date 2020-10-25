module ActionDispatch
  class Request
    class Utils
      ACTIONS_NOT_REQUIRING_NAME_PARAMETER = %w[user_js user_css meta_js].freeze

      def self.check_param_encoding(params)
        case params
        when Array
          params.each { |element| check_param_encoding(element) }
        when Hash
          params.each do |k, v|
            # For ID parameter, clean instead of raise.
            if k == :id
              params[k] = ActiveSupport::Multibyte::Unicode.tidy_bytes(v)
            # Name parameter is not required for script install
            elsif k == :name && params[:controller] == 'scripts' && ACTIONS_NOT_REQUIRING_NAME_PARAMETER.include?(params[:action])
              params[k] = nil
            # 404 with bad params
            elsif k == :path && params[:action] == 'routing_error'
              params[k] = ActiveSupport::Multibyte::Unicode.tidy_bytes(v)
            else
              check_param_encoding(v)
            end
          end
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
