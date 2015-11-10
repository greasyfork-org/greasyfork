class ScriptSetScriptInclusion < ActiveRecord::Base

	belongs_to :parent, :class_name => 'ScriptSet', :touch => true
	belongs_to :child, :class_name => 'Script'
end
