class ScriptSet < ApplicationRecord
  belongs_to :user
  has_many :set_inclusions, class_name: 'ScriptSetSetInclusion', foreign_key: :parent_id, autosave: true, dependent: :destroy, inverse_of: :parent
  has_many :script_inclusions, class_name: 'ScriptSetScriptInclusion', foreign_key: :parent_id, autosave: true, dependent: :destroy, inverse_of: :parent
  has_many :automatic_set_inclusions, class_name: 'ScriptSetAutomaticSetInclusion', foreign_key: :parent_id, autosave: true, dependent: :destroy, inverse_of: :parent

  validates :name, presence: true
  validates :description, presence: true

  validates :name, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  strip_attributes

  # Parents is used to prevent infinite recursion.
  def scripts(script_subset, parents = [], as_ids: false)
    r = Set.new

    # favorites can only directly include scripts
    if favorite
      r.merge(child_script_inclusions)
      return r
    end

    # prevent infinite recursion
    return r if parents.include?(self)

    parents = parents.dup
    parents << self

    script_transformer = lambda { |scope|
      next scope unless as_ids

      scope.is_a?(Array) ? scope.map(&:id) : scope.pluck(:id)
    }

    child_set_inclusions.map { |set| set.scripts(script_subset, parents, as_ids:) }.each { |s| r.merge(s) }
    child_automatic_set_inclusions.map { |set| set.scripts(script_subset) }.map { |scripts| script_transformer.call(scripts) }.each { |s| r.merge(s) }
    r.merge(script_transformer.call(child_script_inclusions))
    child_set_exclusions.map { |set| set.scripts(script_subset, parents, as_ids:) }.each { |s| r.subtract(s) }
    child_automatic_set_exclusions.map { |set| set.scripts(script_subset) }.map { |scripts| script_transformer.call(scripts) }.each { |s| r.subtract(s) }
    r.subtract(script_transformer.call(child_script_exclusions))

    r
  end

  def child_set_inclusions
    set_inclusions.reject(&:marked_for_destruction?).reject(&:exclusion).map(&:child)
  end

  def child_set_exclusions
    set_inclusions.reject(&:marked_for_destruction?).select(&:exclusion).map(&:child)
  end

  def child_script_inclusions
    si = script_inclusions
    si = if new_record?
           si.reject(&:marked_for_destruction?).reject(&:exclusion)
         else
           si.includes(:child).where(exclusion: false)
         end
    si.map(&:child)
  end

  def child_script_exclusions
    si = script_inclusions
    si = if new_record?
           si.reject(&:marked_for_destruction?).select(&:exclusion)
         else
           si.includes(:child).where(exclusion: true)
         end
    si.map(&:child)
  end

  def child_automatic_set_inclusions
    automatic_set_inclusions.reject(&:marked_for_destruction?).reject(&:exclusion)
  end

  def child_automatic_set_exclusions
    automatic_set_inclusions.reject(&:marked_for_destruction?).select(&:exclusion)
  end

  def add_child(child, exclusion: false)
    if child.is_a?(ScriptSet)
      return false if child_set_inclusions.include?(child) || child_set_exclusions.include?(child)

      # Include parent due to https://github.com/rails/rails/issues/26817
      set_inclusions.build(parent: self, child:, exclusion:)
      return true
    end
    if child.is_a?(Script)
      return false if child_script_inclusions.include?(child) || child_script_exclusions.include?(child)

      # Include parent due to https://github.com/rails/rails/issues/26817
      script_inclusions.build(parent: self, child:, exclusion:)
      return true
    end
    return false
  end

  def remove_child(child)
    if child.is_a?(ScriptSet)
      si = set_inclusions.find { |s| s.child == child }
      si&.mark_for_destruction
      return !si.nil?
    end
    if child.is_a?(Script)
      si = script_inclusions.find { |s| s.child == child }
      si&.mark_for_destruction
      return !si.nil?
    end
    return false
  end

  def add_automatic_child(new_asi)
    return false if child_automatic_set_inclusions.any? { |asi| asi.script_set_automatic_type_id == new_asi.script_set_automatic_type_id && (asi.value == new_asi.value || (asi.value.nil? && new_asi.value.nil?)) } || child_automatic_set_exclusions.any? { |asi| asi.script_set_automatic_type_id == new_asi.script_set_automatic_type_id && (asi.value == new_asi.value || (asi.value.nil? && new_asi.value.nil?)) }

    automatic_set_inclusions.build({ parent: self, script_set_automatic_type_id: new_asi.script_set_automatic_type_id, value: new_asi.value, exclusion: new_asi.exclusion })
    return true
  end

  def self.favorites_first(arr)
    return arr.sort do |a, b|
      next -1 if a.favorite && !b.favorite
      next 1 if !a.favorite && b.favorite

      next a.name <=> b.name
    end
  end

  def display_name
    return favorite ? I18n.t('script_sets.favorites_name') : name
  end
end
