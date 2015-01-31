class Screenshot < ActiveRecord::Base

	has_and_belongs_to_many :script_versions

	has_attached_file :screenshot, :styles => { :thumb => "150x150>" }

	validates_attachment_content_type :screenshot, :content_type => ["image/jpeg", "image/gif", "image/png"]
	validates_with AttachmentSizeValidator, :attributes => :screenshot, :less_than => Rails.configuration.screenshot_max_size

	validates :caption, length: {maximum: 500}
end
