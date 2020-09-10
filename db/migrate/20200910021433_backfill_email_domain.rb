class BackfillEmailDomain < ActiveRecord::Migration[6.0]
  def change
    User.where.not(email: nil).find_each do |user|
      user.email_domain = user.email.split('@').last
    end
  end
end
