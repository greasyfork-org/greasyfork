class Script < ActiveRecord::Base
	belongs_to :user
	has_many :script_versions
	has_many :script_applies_tos, :dependent => :delete_all
	has_many :discussions, -> { readonly.order('DateInserted').where('Closed = 0') }, :class_name => 'ForumDiscussion', :foreign_key => 'ScriptID'
	has_many :assessments, :dependent => :delete_all
	belongs_to :script_type
	belongs_to :script_sync_source
	belongs_to :script_sync_type
	belongs_to :license

	scope :not_deleted, -> {where(:moderator_deleted => false).where(:script_type_id != 4)}
	scope :active, -> {not_deleted.includes(:assessments).where(:assessments => { :id => nil })}
	scope :listable, -> {active.where(:script_type_id => 1)}
	scope :libraries, -> {active.where(:script_type_id => 3)}
	scope :under_assessment, -> {not_deleted.joins(:assessments).includes(:user).uniq}
	scope :reported, -> {not_deleted.joins(:discussions).includes(:user).uniq.where('GDN_Discussion.Rating = 1').where('Closed = 0')}

	validates_presence_of :name, :message => 'is required - specify one with @name'
	validates_presence_of :description, :message => 'is required - specify one with @description', :unless => Proc.new {|r| r.deleted?}
	validates_presence_of :user_id, :code_updated_at, :script_type

	validates_length_of :name, :maximum => 100
	validates_length_of :description, :maximum => 500
	validates_length_of :additional_info, :maximum => 50000

	validates_each(:description, :allow_nil => true, :allow_blank => true) do |record, attr, value|
		# exempt scripts that are (being) deleted
		next if record.deleted?

		record.errors.add(attr, "must not be the same as the name") if value == record.name
	end

	validates_format_of :sync_identifier, :with => URI::regexp(%w(http https)), :message => 'must be an HTTP or HTTPS URL.', :if => Proc.new {|r| r.script_sync_source_id == 1}

	strip_attributes :only => [:name, :description, :additional_info]

	def apply_from_script_version(script_version)
		self.additional_info = script_version.additional_info
		self.additional_info_markup = script_version.additional_info_markup

		meta = ScriptVersion.parse_meta(script_version.rewritten_code)
		self.name = meta.has_key?('name') ? meta['name'].first : nil
		self.description = meta.has_key?('description') ? meta['description'].first : nil

		self.script_applies_tos = script_version.calculate_applies_to_names.map do |pattern, name|
			ScriptAppliesTo.new({:pattern => pattern, :display_text => name})
		end

		self.assessments = script_version.disallowed_requires_used.map do |script_url|
			Assessment.new({:assessment_reason => AssessmentReason.first, :details => script_url, :script => self})
		end
		if new_record? or self.code_updated_at.nil?
			self.code_updated_at = Time.now
		else
			newest_sv = get_newest_saved_script_version
			self.code_updated_at = Time.now if newest_sv.nil? or newest_sv.code != script_version.code
		end

		self.license_text = meta.has_key?('license') ? meta['license'].first : nil
		if self.license_text.nil?
			self.license = nil
		else
			self.license = License.order('priority DESC, id').find do |l|
				self.license_text =~ Regexp.new(l.pattern)
			end
		end
	end

	def get_newest_saved_script_version
		# get the most recently saved record
		script_versions.reverse.each do |sv|
			return sv if !sv.new_record?
		end
		return nil
	end

	def self.record_install(id, ip)
		Script.connection.execute("INSERT IGNORE INTO daily_install_counts (script_id, ip) VALUES (#{Script.connection.quote_string(id)}, '#{Script.connection.quote_string(ip)}');")
	end

	def active?
		assessments.empty?
	end

	def slugify(name)
		# take out swears
		r = name.downcase.gsub(/motherfucking|motherfucker|fucking|fucker|fucks|fuck|shitty|shits|shit|niggers|nigger|cunts|cunt/, '')
		# multiple non-alphas into one
		r.gsub!(/([^[:alnum:]])[^[:alnum:]]+/) {|s| $1}
		# leading non-alphas
		r.gsub!(/^[^[:alnum:]]+/, '')
		# trailing non-alphas
		r.gsub!(/[^[:alnum:]]+$/, '')
		# non-alphas into dashes
		r.gsub!(/[^[:alnum:]]/, '-')
		# use "script" if we don't have something suitable
		r = 'script' if r.empty?
		return r
	end

	# Full name minus URL-y characters
	def url_name
		return name.gsub(/[\?\&\/\#\.]+/, '')
	end

	def to_param
		"#{id}-#{slugify(name)}"
	end

	def deleted?
		!script_type_id.nil? && script_type_id == 4
	end
end
