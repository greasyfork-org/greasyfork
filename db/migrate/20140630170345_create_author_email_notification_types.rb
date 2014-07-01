class CreateAuthorEmailNotificationTypes < ActiveRecord::Migration
	def change
		create_table :author_email_notification_types do |t|
			t.string :name, :limit => 20, :null => false
			t.string :description, :limit => 100, :null => false
		end
		add_column :users, :author_email_notification_type_id, :integer, :null => false, :default => 1
		reversible do |dir|
			dir.up do
				execute <<-EOF
					INSERT INTO author_email_notification_types (name, description) VALUES 
						('None', 'No automatic e-mail notification'),
						('Discussions', 'Automatic e-mail notification on new discussions'),
						('Posts', 'Automatic e-mail notification on new discussions and posts');
				EOF
			end
		end
	end
end
