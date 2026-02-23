class AddBraveBrowser < ActiveRecord::Migration[8.1]
  def change
    Browser.create!(code: 'brave', name: "Brave")
  end
end
