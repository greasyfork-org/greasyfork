class ScriptSetAutomaticSetInclusion < ActiveRecord::Base

	belongs_to :parent, :class_name => 'ScriptSet', :touch => true
	belongs_to :script_set_automatic_type

	def name
		return script_set_automatic_type.name if script_set_automatic_type_id == 1
		return "Scripts for " + value if script_set_automatic_type_id == 2 and !value.nil? and !value.empty?
		return "Scripts for all sites" if script_set_automatic_type_id == 2
		return "Scripts by " + User.find(value).name if script_set_automatic_type_id == 3
		return "Scripts in " + Locale.find(value).display_text if script_set_automatic_type_id == 4
	end

	def param_value
		return "#{script_set_automatic_type_id}-#{value}"
	end

	def self.from_param_value(v, exclusion = false)
		parts = v.split('-', 2)
		return ScriptSetAutomaticSetInclusion.new({:script_set_automatic_type_id => parts[0], :value => parts[1], :exclusion => exclusion})
	end

	def scripts
		return Script.listable if script_set_automatic_type.id == 1
		return Script.listable.joins(:script_applies_tos).where(['text = ?', value]) if script_set_automatic_type.id == 2 and !value.nil? and !value.empty?
		return Script.listable.for_all_sites if script_set_automatic_type.id == 2
		return Script.listable.where(:user_id => value) if script_set_automatic_type.id == 3
		return Script.listable.where(:locale_id => value) if script_set_automatic_type.id == 4
	end
end
