class AddCroatian < ActiveRecord::Migration[7.0]
  def change
    Locale.where(code: 'hr').update_all(ui_available: true)
  end
end
