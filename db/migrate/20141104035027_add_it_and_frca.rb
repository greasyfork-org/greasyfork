class AddItAndFrca < ActiveRecord::Migration
	def change
		execute <<-EOF
			update locales set ui_available = true where code in ('it', 'fr-CA')
		EOF
	end
end
