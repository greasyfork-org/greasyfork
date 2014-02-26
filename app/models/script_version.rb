require 'uri'

class ScriptVersion < ActiveRecord::Base
	belongs_to :script

	validates_presence_of :code

	validates_length_of :additional_info, :maximum => 10000
	validates_length_of :code, :maximum => 500000
	validates_length_of :changelog, :maximum => 500

	validates_each(:code, :allow_nil => true, :allow_blank => true) do |record, attr, value|
		meta = ScriptVersion.parse_meta(value)

		#@@required_meta.each do |rm|
		#	record.errors.add(attr, "must contain a meta @#{rm}") unless meta.has_key?(rm)
		#end

		if meta.has_key?('require')
			allowed_requires = AllowedRequire.all
			meta['require'].each do |script_url|
				record.errors.add(attr, "cannot @require from #{script_url}") if allowed_requires.index { |ar| script_url =~ Regexp.new(ar.pattern) }.nil?
			end
		end

		disallowed_codes = DisallowedCode.all
		disallowed_codes.each do |dc|
			record.errors.add(attr, "contains disallowed code") if value =~ Regexp.new(dc.pattern)
		end
	end

	# this requires the script id to be set so may be skipped for new scripts
	after_create do |record|
		record.rewritten_code = record.calculate_rewritten_code if record.rewritten_code == 'placeholder'
		record.save!
	end

	def get_rewritten_meta_block
		ScriptVersion.get_meta_block(rewritten_code)
	end

	def calculate_rewritten_code
		return 'placeholder' if script.nil? or script.new_record?
		rewritten_meta = inject_meta({
			:version => version,
			:updateURL => Rails.application.routes.url_helpers.script_meta_js_path(:script_id => script.id, :only_path => false),
			:installURL => nil,
			:downloadURL => Rails.application.routes.url_helpers.script_user_js_path(:script_id => script.id, :only_path => false),
			:namespace => Rails.application.routes.url_helpers.script_path(:id => script.id, :only_path => false)
		})
		return nil if rewritten_meta.nil?
		return rewritten_meta + ScriptVersion.get_code_block(code)
	end

	def inject_meta(replacements)
		meta_block = ScriptVersion.get_meta_block(code)
		return nil if meta_block.nil?

		# handle strings or symbols as the keys
		replacement_keys = replacements.keys.map{|s|s.to_s}
		replacements = replacements.with_indifferent_access

		# replace any existing values
		meta_lines = meta_block.split("\n").map do |meta_line|
			next meta_line if replacements.empty?
			meta_match = /\/\/\s+@([a-zA-Z]+)\s+(.*)/.match(meta_line)
			next meta_line if meta_match.nil?
			key = meta_match[1].strip
			value = meta_match[2].strip
			# replace the first one, remove any subsequent ones
			if replacement_keys.include?(key)
				if replacements.has_key?(key) and !value.nil?
					replacement = replacements.delete(key)
					next nil if replacement.nil?
					next meta_line.sub(value, replacement)
				end
				next nil
			end
			next meta_line
		end

		meta_lines.compact!

		# add new values
		if !replacements.empty?
			# nils here would indicate a removal that wasn't there, so ignore that
			new_lines = replacements.delete_if{|k,v|v.nil?}.map { |k, v| "// @#{k} #{v}" }
			close_meta = meta_lines.pop
			meta_lines.concat(new_lines)
			meta_lines << close_meta
		end

		return meta_lines.join("\n")
	end

	def calculate_applies_to_names
		meta = ScriptVersion.parse_meta(code)
		patterns = []
		meta.each { |k, v| patterns.concat(v) if ['include', 'match'].include?(k) }

		return [] if patterns.empty?
		return [] if !(patterns & @@applies_to_all_patterns).empty?

		applies_to_names = []
		patterns.each do |p|
			# senseless wildcard before protocol
			m = p.match(/^\*(https?:.*)/i)
			p = m[1] if !m.nil?

			# protocol wild-cards
			p.sub!(/^\*:/i, 'http:')
			p.sub!(/^http\*:/i, 'http:')

			# subdomain wild-cards - http://*.example.com and http://*example.com
			m = p.match(/^([a-z]+:\/\/)\*\.?([a-z0-9\-]+(?:.[a-z0-9\-]+)+.*)/i)
			p = m[1] + m[2] if !m.nil?

			# protocol and subdomain wild-cards - *example.com and *.example.com
			m = p.match(/^\*\.?([a-z0-9\-]+\.[a-z0-9\-]+.*)/i)
			p = 'http://' + m[1] if !m.nil?

			# protocol and subdomain wild-cards - http*.example.com, http*example.com, http*//example.com
			m = p.match(/^http\*(?:\/\/)?\.?((?:[a-z0-9\-]+)(?:\.[a-z0-9\-]+)+.*)/i)
			p = 'http://' + m[1] if !m.nil?

			# tld wildcards - http://example.* - switch to .tld
			m = p.match(/^([a-z]+:\/\/[a-z0-9\-]+(?:\.[a-z0-9\-]+)*\.)\*(.*)/)
			p = m[1] + 'tld' + m[2] if !m.nil?

			# grab up to the first *
			pre_wildcard = p.split('*').first
			begin
				uri = URI(pre_wildcard)
				if uri.host.nil?
					applies_to_names << p
				else
					if uri.host.ends_with?('.tld')
						@@tld_expansion.each do |tld|
							applies_to_names << uri.host.sub(/tld$/i, tld)
						end
					# "example.com."
					elsif uri.host.ends_with?('.')
						applies_to_names << uri.host[0, uri.host.length - 1]
					else
						applies_to_names << uri.host
					end
				end
			rescue ArgumentError
				logger.warn "Unrecognized pattern '" + p + "'"
				applies_to_names << p
			rescue URI::InvalidURIError
				logger.warn "Unrecognized pattern '" + p + "'"
				applies_to_names << p
			end
		end
		return applies_to_names.uniq
	end

	# Returns the meta for this script in a hash of key to array of values
	def self.parse_meta(c)
		meta = {}
		meta_block = ScriptVersion.get_meta_block(c)
		return meta if meta_block.nil?
		# can these be multiline?
		meta_block.split("\n").each do |meta_line|
			meta_match = /\/\/\s+@([a-zA-Z]+)\s+(.*)/.match(meta_line)
			next if meta_match.nil?
			key = meta_match[1].strip
			value = meta_match[2].strip
			if meta.has_key?(key)
				meta[key] << value
			else
				meta[key] = [value]
			end
		end
		return meta
	end

	def self.get_meta_block(c)
		start_block = c.index(@@meta_start_comment)
		return nil if start_block.nil?
		end_block = c.index(@@meta_end_comment, start_block)
		return nil if end_block.nil?
		return c[start_block..end_block+@@meta_end_comment.length]
	end

	def self.get_code_block(c)
		meta_start = c.index(@@meta_start_comment)
		return c if meta_start.nil?
		meta_end = c.index(@@meta_end_comment, meta_start) + @@meta_end_comment.length
		return (meta_start == 0 ? '' : c[0..meta_start-1]) + c[meta_end..c.length]
	end


private

	# handled by script
	#@@required_meta = ['name', 'description']

	@@meta_start_comment = '// ==UserScript=='
	@@meta_end_comment = '// ==/UserScript=='

	@@applies_to_all_patterns = ['http://*', 'https://*', 'http://*/*', 'https://*/*', 'http*://*', 'http*://*/*', '*', '*://*', '*://*/*']

	@@tld_expansion = ['com', 'net', 'org', 'de', 'co.uk']

end
