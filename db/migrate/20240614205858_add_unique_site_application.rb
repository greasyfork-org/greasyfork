class AddUniqueSiteApplication < ActiveRecord::Migration[7.1]
  def change
    add_index :site_applications, [:text, :domain], unique: true
  end
end
