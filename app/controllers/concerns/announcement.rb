module Announcement
  extend ActiveSupport::Concern

  AnnouncementStruct = Struct.new(:key, :content)

  class_methods do
    def show_announcement(key:, show_if:, content:)
      before_action do
        @announcement = AnnouncementStruct.new(key, content) if current_user && !current_user.seen_announcement?(key.to_sym) && instance_exec(&show_if)
      end
    end
  end
end