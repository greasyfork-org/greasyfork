class FilipinoAvailable < ActiveRecord::Migration[8.1]
  def change
    Locale.where(code: 'fil').update!(native_name: 'Filipino')
  end
end
