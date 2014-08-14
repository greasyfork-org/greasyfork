class Script < ActiveRecord::Base
	belongs_to :user
	has_many :script_versions
	has_many :script_applies_tos, -> {order(:text)}, :dependent => :delete_all, :autosave => true
	has_many :discussions, -> { readonly.order('COALESCE(DateLastComment, DateInserted)').where('Closed = 0') }, :class_name => 'ForumDiscussion', :foreign_key => 'ScriptID'
	has_many :assessments, :dependent => :delete_all, :autosave => true
	has_many :cpd_duplication_scripts
	has_many :cpd_duplications, :through => :cpd_duplication_scripts
	belongs_to :script_type
	belongs_to :script_sync_source
	belongs_to :script_sync_type
	belongs_to :script_delete_type
	belongs_to :license
	belongs_to :locale

	scope :not_deleted, -> {where('script_delete_type_id is null')}
	scope :active, -> {not_deleted.where(:uses_disallowed_external => false)}
	scope :listable, -> {active.where(:script_type_id => 1)}
	scope :libraries, -> {active.where(:script_type_id => 3)}
	scope :under_assessment, -> {not_deleted.where(:uses_disallowed_external => true).includes(:assessments).includes(:user).uniq}
	scope :reported, -> {not_deleted.joins(:discussions).includes(:user).uniq.where('GDN_Discussion.Rating = 1').where('Closed = 0')}
	scope :for_all_sites, -> {includes(:script_applies_tos).references(:script_applies_tos).where('script_applies_tos.id IS NULL')}

	validates_presence_of :name, :message => 'is required - specify one with @name', :unless => Proc.new {|s| s.library?}
	validates_presence_of :name, :message => 'is required', :if => Proc.new {|s| s.library?}
	validates_presence_of :description, :message => 'is required - specify one with @description', :unless => Proc.new {|r| r.deleted? || r.library?}
	validates_presence_of :description, :message => 'is required', :unless => Proc.new {|r| r.deleted? || !r.library?}
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

	strip_attributes :only => [:name, :description, :additional_info, :sync_identifier]

	def apply_from_script_version(script_version)
		self.additional_info = script_version.additional_info
		self.additional_info_markup = script_version.additional_info_markup

		# keep previous name and description for libraries
		meta = ScriptVersion.parse_meta(script_version.rewritten_code)
		meta_name = meta.has_key?('name') ? meta['name'].first : nil
		self.name = meta_name unless library? and meta_name.nil?
		meta_description = script_version.description
		self.description = meta_description unless library? and meta_description.nil?

		self.script_applies_tos.each {|sat| sat.mark_for_destruction }
		script_version.calculate_applies_to_names.each do |text, domain|
			self.script_applies_tos.build({:text => text, :domain => domain})
		end

		self.assessments.each {|a| a.mark_for_destruction }
		self.uses_disallowed_external = false
		script_version.disallowed_requires_used.each do |script_url|
			self.uses_disallowed_external = true
			self.assessments.build({:assessment_reason => AssessmentReason.first, :details => script_url})
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

		self.namespace = meta.has_key?('namespace') ? meta['namespace'].first : nil

		self.contribution_url = !meta.has_key?('contributionURL') ? nil : meta['contributionURL'].find {|url|
			URI::regexp(%w(http https)) =~ url
		}
		self.contribution_amount = (!self.contribution_url.nil? && meta.has_key?('contributionAmount')) ? meta['contributionAmount'].first : nil

		if meta.has_key?('supportURL')
			self.support_url = meta['supportURL'].find {|url|
				next false if url.size > 500
				# mailto is always OK
				next true if URI::regexp(%w(mailto)) =~ url
				# http(s) is also OK
				next false unless URI::regexp(%w(http https)) =~ url
				# avoid self-linking, there's UI on the same page for discussions
				begin
					next URI(url).host != 'greasyfork.org'
				rescue
					next false
				end
			}
		else
			self.support_url = nil
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
		!deleted? and !uses_disallowed_external
	end

	def library?
		script_type_id == 3
	end

	def listable?
		active? and script_type_id == 1
	end

	def unlisted?
		script_type_id == 2
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
		!script_delete_type.nil?
	end

	def detect_locale
		ft = full_text
		return if ft.nil?
		begin
			dl_lang_code = DetectLanguage.simple_detect(ft)
		rescue Exception => ex
			Rails.logger.error "Could not detect language - #{ex}"
		end
		return nil if dl_lang_code.nil?
		locales = Locale.where(:detect_language_code => dl_lang_code)
		if locales.empty?
			Rails.logger.error "detect_language gave unrecognized code #{dl_lang_code}"
			return nil
		end
		return locales.first
	end

	def license_display
		if license.nil?
			return "<i>#{I18n.t('scripts.no_license')}</i>".html_safe if license_text.nil?
			return license_text
		end
		return license.html.html_safe
	end

private

	# all text content of this script (for language detection)
	def full_text
		parts = []
		parts << name if !name.nil? and !name.empty?
		parts << description if !description.nil? and !description.empty?
		additional_text = ApplicationController.helpers.format_user_text_as_plain(additional_info, additional_info_markup)
		parts << additional_text if !additional_text.nil? and !additional_text.empty?
		return nil if parts.empty?
		return parts.join("\n")
	end
end
