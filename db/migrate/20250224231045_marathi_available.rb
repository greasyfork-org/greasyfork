class MarathiAvailable < ActiveRecord::Migration[8.0]
  def change
    Locale.where(code: 'mr').update!(native_name: 'मराठी', ui_available: true)
  end
end
