class AddUpDownRatingCounts < ActiveRecord::Migration
	def change
		add_column :scripts, :good_ratings, :int, :nil => false, :default => 0
		add_column :scripts, :ok_ratings, :int, :nil => false, :default => 0
		add_column :scripts, :bad_ratings, :int, :nil => false, :default => 0
	end
end
