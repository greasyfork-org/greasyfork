class TrAvailable < ActiveRecord::Migration
	def change
		execute <<-EOF
			update locales set ui_available = true where code in ('tr')
		EOF
	end
end
