class BackfillDiscussionPubliclyVisisble < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    Discussion.includes(:script).find_each do |d|
      d.calculate_publicly_visible
      d.save(validate: false)
    end
  end
end
