class AddCzech < ActiveRecord::Migration
	def change
		execute <<-EOF
			update locales set ui_available = true where code in ('cs')
		EOF
	end
end
