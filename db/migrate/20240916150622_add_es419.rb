class AddEs419 < ActiveRecord::Migration[7.2]
  def change
    Locale.create!(code: 'es-419', english_name: 'Spanish, Latin American', native_name: 'Español Latinoamericano', ui_available: true)
  end
end
