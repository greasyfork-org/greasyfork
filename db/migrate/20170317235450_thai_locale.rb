class ThaiLocale < ActiveRecord::Migration[5.0]
  def change
    Locale.where(code: 'th').update_all(ui_available: true)
  end
end
