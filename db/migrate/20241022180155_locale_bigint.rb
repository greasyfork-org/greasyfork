class LocaleBigint < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :antifeatures, :locales
    change_column :antifeatures, :locale_id, :bigint

    change_column :locales, :id, :bigint, auto_increment: true
    add_foreign_key :antifeatures, :locales
  end
end
