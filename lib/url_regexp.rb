require 'regexp_parser'

class UrlRegexp
  def self.expand(regexp)
    begin
      Regexp.new(regexp)
    rescue StandardError
      Rails.logger.warn("#{regexp} is not a valid regexp")
      return []
    end

    tree = Regexp::Parser.parse(regexp)
    result = Node.new(expand_group(tree))
    strings = result.every
    strings.each do |s|
      Rails.logger.warn("#{s} does not match #{regexp}") unless Regexp.new(regexp).match?(s)
    end
    strings
  end

  def self.expand_group(group)
    return handle_quantifier(group) if group.quantifier

    case group
    when Regexp::Expression::Root, Regexp::Expression::Alternative
      de_single_element(group.expressions.map { |sub| expand_group(sub) }.flatten.compact)
    when Regexp::Expression::Group::Capture, Regexp::Expression::Assertion::Lookahead, Regexp::Expression::Group::Passive
      de_single_element(group.map { |sub| expand_group(sub) }.flatten)
    when Regexp::Expression::Alternation
      OptionNode.new(de_single_element(group.map { |sub| expand_group(sub) }))
    when Regexp::Expression::Anchor::BeginningOfLine, Regexp::Expression::Anchor::EndOfLine, Regexp::Expression::Assertion::NegativeLookahead
      ''
    when Regexp::Expression::EscapeSequence::Literal
      group.char
    when Regexp::Expression::Literal
      group.to_s
    when Regexp::Expression::CharacterType::Any, Regexp::Expression::CharacterType::NonSpace, Regexp::Expression::CharacterType::Word, Regexp::Expression::CharacterType::NonDigit
      'a'
    when Regexp::Expression::Anchor::WordBoundary
      '.'
    when Regexp::Expression::CharacterType::Digit
      '0'
    when Regexp::Expression::CharacterSet
      if group.negated?
        'a'
      elsif group.expressions.first.is_a?(Regexp::Expression::CharacterSet::Range)
        expand_group(group.expressions.first.expressions.first)
      else
        expand_group(group.expressions.first)
      end
    when Regexp::Expression::Backreference::Base
      ''
    when Regexp::Expression::CharacterType::Space
      ' '
    else
      raise "Unknown class #{group.class}"
    end
  end

  def self.de_single_element(array)
    array.one? ? array.first : array
  end

  def self.handle_quantifier(group)
    return '' if group.quantifier.min == 0

    gg = group.dup
    gg.quantifier = nil
    return expand_group(gg) if group.quantifier.min == 1

    Array.new(group.quantifier.min) { expand_group(gg) }.compact
  end

  class Node
    def initialize(children)
      @children = Array(children)
    end

    def simplify
      @children.flatten.compact
    end

    def every
      self.class.reduce_options(simplify)
    end

    def self.reduce_options(options)
      options.reduce(['']) do |s, n|
        next Array(s).map { |a| a + n } if n.is_a?(String)

        Array(s).product(n.every).map(&:join)
      end
    end
  end

  class OptionNode
    attr_accessor :options

    def initialize(options)
      @options = options
    end

    def every
      @options.map do |o|
        next o if o.is_a?(String)

        Node.reduce_options(Array(o))
      end.flatten
    end
  end
end
