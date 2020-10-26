class DedupeUsernames < ActiveRecord::Migration[6.0]
  def up
    User.connection.select_values('select name from users group by name having count(*) > 1').each do |name|
      users = User.where(name: name).order(id: :desc)
      first_user = nil
      index = 2
      users.each do |user|
        if first_user.nil?
          first_user = user
          next
        end
        index += 1 until User.where(name: "#{name} #{index}").none?
        user.update(name: "#{name} #{index}")
      end
    end
  end
end
