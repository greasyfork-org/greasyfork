class SerbianAvailable < ActiveRecord::Migration[5.2]
  def change
    Locale.find_by(code: 'sr').update(ui_available: true)
  end
end
