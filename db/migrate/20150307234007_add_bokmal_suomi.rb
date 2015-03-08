class AddBokmalSuomi < ActiveRecord::Migration
	def change
		execute <<-EOF
			update locales set ui_available = true where code in ('fi', 'nb')
		EOF
	end
end
