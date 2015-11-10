class AddSvRoLocales < ActiveRecord::Migration
	def change
		execute <<-EOF
			update locales set ui_available = true where code in ('ro', 'sv')
		EOF
	end
end
