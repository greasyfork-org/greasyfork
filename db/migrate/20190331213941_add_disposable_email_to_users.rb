class AddDisposableEmailToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :disposable_email, :boolean
    execute 'update users set disposable_email = false'
  end
end
