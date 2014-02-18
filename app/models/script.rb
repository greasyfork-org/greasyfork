class Script < ActiveRecord::Base
	belongs_to :user
	has_many :script_versions

	validates_presence_of :name, :description, :user_id

	validates_length_of :name, :maximum => 100
	validates_length_of :description, :maximum => 500
	validates_length_of :additional_info, :maximum => 10000

	validates_each(:description, :allow_nil => true, :allow_blank => true) do |record, attr, value|
		record.errors.add(attr, "must not be the same as the name") if value == record.name
	end

	def apply_from_script_version(script_version)
		self.additional_info = script_version.additional_info

		meta = script_version.parse_meta
		self.name = meta.has_key?('name') ? meta['name'].first : nil
		self.description = meta.has_key?('description') ? meta['description'].first : nil
	end

	def self.record_install(id, ip)
		Script.connection.execute("INSERT IGNORE INTO daily_install_counts (script_id, ip) VALUES (#{Script.connection.quote_string(id)}, '#{Script.connection.quote_string(ip)}');")
	end
end
