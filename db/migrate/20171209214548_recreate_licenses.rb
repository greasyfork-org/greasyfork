class RecreateLicenses < ActiveRecord::Migration[5.1]
  def change
    execute 'update scripts set license_id = null'
    drop_table :licenses
    create_table :licenses do |t|
      t.string :code, limit: 100, null: false, unique: true
      t.string :name, limit: 250, null: false
      t.string :url, limit: 250
    end
  end
end
