class ScriptCodesToCompressedFormat < ActiveRecord::Migration
	def change
		execute <<-EOF
			ALTER TABLE script_codes ROW_FORMAT=COMPRESSED
		EOF
	end
end
