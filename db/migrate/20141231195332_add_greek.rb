class AddGreek < ActiveRecord::Migration
	def change
		execute <<-EOF
			update locales set ui_available = true where code in ('el')
		EOF
	end
end
