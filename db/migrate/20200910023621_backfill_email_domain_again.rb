class BackfillEmailDomainAgain < ActiveRecord::Migration[6.0]
  def change
    User
        .where(email_domain: nil)
        .where.not(email: nil)
        .pluck(:id, :email)
        .map { |id, email| [id, email.split('@').last]}
        .group_by { |id, email_domain| email_domain }
        .map { |email_domain, ids_and_email_domains| [email_domain, ids_and_email_domains.map(&:first)] }
        .each do |email_domain, ids|
      User.where(id: ids).update_all(email_domain: email_domain)
    end
  end
end
