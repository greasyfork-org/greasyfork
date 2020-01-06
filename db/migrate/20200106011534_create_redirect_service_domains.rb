class CreateRedirectServiceDomains < ActiveRecord::Migration[6.0]
  def change
    create_table :redirect_service_domains do |t|
      t.string :domain, limit: 50, null: false
    end
  end
end
