class ClearNotificationNilItem < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    Notification.includes(:item).find_each.select{|n| n.item.nil?}.each(&:destroy)
  end
end
