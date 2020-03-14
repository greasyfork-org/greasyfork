class ScriptSimilarity < ApplicationRecord
  belongs_to :script
  belongs_to :other_script, class_name: 'Script'
end
