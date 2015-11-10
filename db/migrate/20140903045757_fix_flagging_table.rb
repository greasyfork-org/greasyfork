class FixFlaggingTable < ActiveRecord::Migration
	def change
		execute <<-EOF
			ALTER TABLE GDN_Flag CHANGE ForeignUrl ForeignURL VARCHAR(150)
		EOF
	end
end
