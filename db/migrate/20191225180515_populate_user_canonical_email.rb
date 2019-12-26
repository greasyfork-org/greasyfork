class PopulateUserCanonicalEmail < ActiveRecord::Migration[5.2]
  def up
    User.select(:id, :email, :canonical_email).find_each do |u|
      u.update_column(:canonical_email, EmailAddress.canonical(u.email))
    end unless Rails.env.production?
  end
end
