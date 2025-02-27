class BackfillBlockedUsers < ActiveRecord::Migration[8.0]
  def change
    ['CX D K 58', '17197055000', 'www\\.xbs', 'hjv58\.top'].each do |pattern|
      BlockedUser.create!(pattern:)
    end
  end
end
