class AddArabicUkrainian < ActiveRecord::Migration
	def change
		execute <<-EOF
			update locales set ui_available = true where code in ('ar', 'uk')
		EOF
	end
end
