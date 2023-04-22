class AddSelfUpholdToReport < ActiveRecord::Migration[7.0]
  def change
    add_column :reports, :self_upheld, :boolean, default: false
  end
end
