class AddMarkupToChangelog < ActiveRecord::Migration[5.1]
  def change
    add_column :script_versions, :changelog_markup, :string, limit: 10, null: false, default: 'text', after: 'changelog'
  end
end
