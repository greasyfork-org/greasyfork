class BelorussianAvailable < ActiveRecord::Migration[8.0]
  def change
    Locale.where(code: 'be').update!(native_name: 'Беларуская', ui_available: true)
  end
end
