class ScriptSet < ActiveRecord::Base

	belongs_to :user
	has_many :set_inclusions, :class_name => 'ScriptSetSetInclusion', :foreign_key => :parent_id, :autosave => true
	has_many :script_inclusions, :class_name => 'ScriptSetScriptInclusion', :foreign_key => :parent_id, :autosave => true
	has_many :automatic_set_inclusions, :class_name => 'ScriptSetAutomaticSetInclusion', :foreign_key => :parent_id, :autosave => true

	validates_presence_of :name
	validates_presence_of :description

	strip_attributes

	def scripts(parents = [])
		r = Set.new
		# prevent infinite recursion
		return r if parents.include?(self)
		parents = parents.dup
		parents << self

		child_set_inclusions.map{|set| set.scripts(parents)}.each{|s| r.merge(s)}
		child_automatic_set_inclusions.map{|set| set.scripts}.each{|s| r.merge(s)}
		r.merge(child_script_inclusions)
		child_set_exclusions.map{|set| set.scripts(parents)}.each{|s| r.subtract(s)}
		child_automatic_set_exclusions.map{|set| set.scripts}.each{|s| r.subtract(s)}
		r.subtract(child_script_exclusions)

		return r
	end

	def child_set_inclusions
		set_inclusions.select{|si| !si.marked_for_destruction?}.select{|si| !si.exclusion}.map{|si| si.child}
	end

	def child_set_exclusions
		set_inclusions.select{|si| !si.marked_for_destruction?}.select{|si| si.exclusion}.map{|si| si.child}
	end

	def child_script_inclusions
		script_inclusions.select{|si| !si.marked_for_destruction?}.select{|si| !si.exclusion}.map{|si| si.child}
	end

	def child_script_exclusions
		script_inclusions.select{|si| !si.marked_for_destruction?}.select{|si| si.exclusion}.map{|si| si.child}
	end

	def child_automatic_set_inclusions
		automatic_set_inclusions.select{|si| !si.marked_for_destruction?}.select{|si| !si.exclusion}
	end

	def child_automatic_set_exclusions
		automatic_set_inclusions.select{|si| !si.marked_for_destruction?}.select{|si| si.exclusion}
	end

	def add_child(child, exclusion = false)
		if child.is_a?(ScriptSet)
			return if child_set_inclusions.include?(child)
			set_inclusions.build({:child => child, :exclusion => exclusion})
		elsif child.is_a?(Script)
			return if child_script_inclusions.include?(child)
			script_inclusions.build({:child => child, :exclusion => exclusion})
		elsif child.is_a?(String)
			new_asi = ScriptSetAutomaticSetInclusion.from_param_value(child, exclusion)
			return if child_automatic_set_inclusions.any?{|asi| asi.script_set_automatic_type_id == new_asi.script_set_automatic_type_id && (asi.value == new_asi.value || (asi.value.nil? && new_asi.value.nil?))}
			automatic_set_inclusions.build({:script_set_automatic_type_id => new_asi.script_set_automatic_type_id, :value => new_asi.value, :exclusion => new_asi.exclusion})
		end
	end

end
