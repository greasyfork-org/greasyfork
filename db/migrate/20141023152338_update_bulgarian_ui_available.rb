class UpdateBulgarianUiAvailable < ActiveRecord::Migration
	def change
		execute <<-EOF
			update locales set ui_available = true where code = 'bg'
		EOF
	end
end
