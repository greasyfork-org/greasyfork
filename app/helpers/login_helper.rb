module LoginHelper
  def available_auths
    auths = Rails.application.config.available_auths

    # GitHub does not support multiple allowed callback URLs.
    return auths.except('github') unless greasy?

    auths
  end
end
