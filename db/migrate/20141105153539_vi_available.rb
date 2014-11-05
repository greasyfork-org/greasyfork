class ViAvailable < ActiveRecord::Migration
	def change
		execute <<-EOF
			update locales set ui_available = true where code in ('vi')
		EOF
	end
end
