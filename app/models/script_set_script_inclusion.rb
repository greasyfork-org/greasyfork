class ScriptSetScriptInclusion < ActiveRecord::Base

	belongs_to :parent, :class_name => 'ScriptSet'
	belongs_to :child, :class_name => 'Script'
end
