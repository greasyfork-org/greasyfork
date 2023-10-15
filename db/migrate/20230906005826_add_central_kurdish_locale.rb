class AddCentralKurdishLocale < ActiveRecord::Migration[7.0]
  def change
    Locale.create!(code: 'ckb', english_name: 'Central Kurdish', native_name: 'کوردیی ناوەندی', rtl: true, ui_available: true)
  end
end
