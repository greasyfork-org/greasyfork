class EsperantoAvailable < ActiveRecord::Migration[5.2]
  def up
    Locale.find_by(code: 'eo').update(ui_available: true)
  end
end
