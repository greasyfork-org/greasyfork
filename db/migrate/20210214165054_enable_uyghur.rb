class EnableUyghur < ActiveRecord::Migration[6.1]
  def up
    Locale.where(code: 'ug').update_all(native_name: 'ئۇيغۇر', ui_available: true)
  end
end
