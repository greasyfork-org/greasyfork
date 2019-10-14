class CssParser
  META_START_COMMENT = '/* ==UserStyle=='
  META_END_COMMENT = '==/UserStyle== */'

  class << self
    def get_meta_block(c)
      return nil if c.nil?
      start_block = c.index(META_START_COMMENT)
      return nil if start_block.nil?
      end_block = c.index(META_END_COMMENT, start_block)
      return nil if end_block.nil?
      return c[start_block..end_block+META_END_COMMENT.length]
    end

    # Returns the meta for this script in a hash of key to array of values
    def parse_meta(c)
      meta = {}
      meta_block = get_meta_block(c)
      return meta if meta_block.nil?
      # can these be multiline?
      meta_block.split("\n").each do |meta_line|
        meta_match = /@([a-zA-Z\:\-]+)\s+(.*)/.match(meta_line)
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

    # Returns a two-element array: code before the meta block, code after
    def get_code_blocks(c)
      meta_start = c.index(META_START_COMMENT)
      return [c, ""] if meta_start.nil?
      meta_end = c.index(META_END_COMMENT, meta_start) + META_END_COMMENT.length
      return [(meta_start == 0 ? '' : c[0..meta_start-1]), c[meta_end..c.length]]
    end


    # Inserts, changes, or deletes meta values in the code and returns the entire code
    def inject_meta(c, replacements, additions_if_missing = {})
      meta_block = get_meta_block(c)
      return nil if meta_block.nil?

      # handle strings or symbols as the keys
      replacement_keys = replacements.keys.map{|s|s.to_s}
      replacements = replacements.with_indifferent_access
      additions_if_missing = additions_if_missing.with_indifferent_access
      # replace any existing values
      meta_lines = meta_block.split("\n").map do |meta_line|
        meta_match = /\s*@([a-zA-Z]+)\s+(.*)/.match(meta_line)
        next meta_line if meta_match.nil?
        key = meta_match[1].strip
        value = meta_match[2].strip
        additions_if_missing.delete(key)
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
      replacements.update(additions_if_missing)
      if !replacements.empty?
        # nils here would indicate a removal that wasn't there, so ignore that
        new_lines = replacements.delete_if{|k,v|v.nil?}.map { |k, v| "@#{k} #{v}" }
        close_meta = meta_lines.pop
        meta_lines.concat(new_lines)
        meta_lines << close_meta
      end

      code_blocks = get_code_blocks(c)
      return code_blocks[0] + meta_lines.join("\n") + code_blocks[1]
    end
  end
end