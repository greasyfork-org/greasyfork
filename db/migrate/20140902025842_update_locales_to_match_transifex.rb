class UpdateLocalesToMatchTransifex < ActiveRecord::Migration
	def change
		execute <<-EOF
			insert into locales (code, english_name, native_name, rtl, detect_language_code, ui_available) values
			("fr-CA", "Canadian French", "Français canadien",0,null,0)
		EOF
		execute <<-EOF
			update locales set code = 'pt-PT' where code = 'pt-pt'
		EOF
		execute <<-EOF
			update locales set code = 'pt-BR' where code = 'pt-br'
		EOF
		execute <<-EOF
			update locales set ui_available = true where code IN ('es', 'fr', 'pl')
		EOF
	end
end
