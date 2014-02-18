class ScriptVersion < ActiveRecord::Base
	belongs_to :script

	validates_presence_of :code

	validates_length_of :additional_info, :maximum => 10000
	validates_length_of :code, :maximum => 500000
	validates_length_of :changelog, :maximum => 500

	validates_each(:code, :allow_nil => true, :allow_blank => true) do |record, attr, value|
		meta = record.parse_meta

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

	# Returns the meta for this script in a hash of key to array of values
	def parse_meta
		meta = {}
		meta_block = get_meta_block
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

	def get_meta_block
		start_block = code.index(@@meta_start_comment)
		return nil if start_block.nil?
		end_block = code.index(@@meta_end_comment, start_block)
		return nil if end_block.nil?
		return code[start_block..end_block+@@meta_end_comment.length]
	end

	def calculate_rewritten_code
		rewritten_meta = inject_meta({:version => version, :updateURL => nil, :installURL => nil, :downloadURL => nil})
		return nil if rewritten_meta.nil?
		return rewritten_meta + get_code_block
	end

	def get_code_block
		meta_start = code.index(@@meta_start_comment)
		return code if meta_start.nil?
		meta_end = code.index(@@meta_end_comment, meta_start) + @@meta_end_comment.length
		return (meta_start == 0 ? '' : code[0..meta_start-1]) + code[meta_end..code.length]
	end

	def inject_meta(replacements)
		meta_block = get_meta_block
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

private

	# handled by script
	#@@required_meta = ['name', 'description']

	@@meta_start_comment = '// ==UserScript=='
	@@meta_end_comment = '// ==/UserScript=='

end
