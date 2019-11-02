class ScriptType < ApplicationRecord
  LIBRARY_TYPE_ID = 3

  scope :for_language, -> (lang) { lang.to_s == 'css' ? where.not(id: LIBRARY_TYPE_ID) : all }
end
