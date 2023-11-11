require 'aws-sdk-cloudfront'

class ScriptUpdateCacheClearJob < ApplicationJob
  queue_as :default

  def perform(script_id)
    if !Rails.application.secrets.aws && !Rails.env.production?
      Rails.logger.error('No AWS creds found.')
      return
    end

    cf = Aws::CloudFront::Client.new(
      access_key_id: Rails.application.secrets.aws[:access_key_id],
      secret_access_key: Rails.application.secrets.aws[:secret_access_key],
      region: Rails.application.secrets.aws[:region]
    )

    Rails.application.secrets.aws[:script_cloudfront_distributions].each do |distribution_id|
      resp = cf.create_invalidation({
                                      distribution_id: distribution_id,
                                      invalidation_batch: {
                                        paths: {
                                          quantity: 1,
                                          items: ["/scripts/#{script_id}-*"],
                                        },
                                        caller_reference: DateTime.now.to_s,
                                      },
                                    })

      raise "Error: #{resp}" unless resp.is_a?(Seahorse::Client::Response)

      Rails.logger.info("Created invalidation ##{resp.invalidation.id}.")
    end
  end
end
