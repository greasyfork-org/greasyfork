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
  end
end