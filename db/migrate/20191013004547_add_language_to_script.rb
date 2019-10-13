class AddLanguageToScript < ActiveRecord::Migration[5.2]
  def change
    add_column :scripts, :language, :string, limit: 3, null: false, default: 'js'
  end
end
