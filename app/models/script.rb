class Script < ActiveRecord::Base
	belongs_to :user
	has_many :script_versions
	has_many :script_applies_tos, :dependent => :delete_all

	validates_presence_of :name, :message => 'is required - specify one with @name'
	validates_presence_of :description, :message => 'is required - specify one with @description'
	validates_presence_of :user_id

	validates_length_of :name, :maximum => 100
	validates_length_of :description, :maximum => 500
	validates_length_of :additional_info, :maximum => 10000

	validates_each(:description, :allow_nil => true, :allow_blank => true) do |record, attr, value|
		record.errors.add(attr, "must not be the same as the name") if value == record.name
	end

	def apply_from_script_version(script_version)
		self.additional_info = script_version.additional_info
		self.additional_info_markup = script_version.additional_info_markup

		meta = ScriptVersion.parse_meta(script_version.code)
		self.name = meta.has_key?('name') ? meta['name'].first : nil
		self.description = meta.has_key?('description') ? meta['description'].first : nil

		self.script_applies_tos = script_version.calculate_applies_to_names.map do |name|
			ScriptAppliesTo.new({:display_text => name})
		end
	end

	def self.record_install(id, ip)
		Script.connection.execute("INSERT IGNORE INTO daily_install_counts (script_id, ip) VALUES (#{Script.connection.quote_string(id)}, '#{Script.connection.quote_string(ip)}');")
	end
end
