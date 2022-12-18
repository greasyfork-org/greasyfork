class AddGeorgianLocale < ActiveRecord::Migration[7.0]
  def change
    Locale.where(code: 'ka').update_all(ui_available: true)
  end
end
