class UpdateUighurName < ActiveRecord::Migration[7.0]
  def change
    Locale.where(code: 'ug').update_all(native_name: 'ئۇيغۇرچە')
  end
end
