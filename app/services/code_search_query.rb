class CodeSearchQuery
  MIN_LENGTH = 3

  def self.validate!(text)
    raise ArgumentError, 'Code search query must be a single line' if text.match?(/[\r\n]/)
    raise ArgumentError, "Code search query must be at least #{MIN_LENGTH} characters" if text.length < MIN_LENGTH
  end
end
