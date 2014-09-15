class MarkPtbrAvailable < ActiveRecord::Migration
	def change
		execute <<-EOF
			update locales set native_name = 'Português do Brasil', ui_available = true where code = 'pt-BR'
		EOF
	end
end
