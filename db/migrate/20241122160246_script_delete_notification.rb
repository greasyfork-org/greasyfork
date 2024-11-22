class ScriptDeleteNotification < ActiveRecord::Migration[7.2]
  def change
    Notification.includes(:item).where(item_type: 'Script').select{|n|n.item.nil?}.each(&:destroy)
  end
end
