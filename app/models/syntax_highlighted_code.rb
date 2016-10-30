require 'coderay'

class SyntaxHighlightedCode < ApplicationRecord

	belongs_to :script

	def self.can_highlight?(code)
		return code.length <= Rails.configuration.syntax_highlighting_limit
	end

	def self.highlight(code)
		return nil if !can_highlight?(code)
		return CodeRay.scan(code, :js).div({:css => :class, :line_numbers => :table})
	end
end
