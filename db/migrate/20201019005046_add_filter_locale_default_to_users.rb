class AddFilterLocaleDefaultToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :filter_locale_default, :boolean, default: true, null: false
  end
end
