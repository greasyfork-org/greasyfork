class ScriptType < ApplicationRecord
  PUBLIC_TYPE_ID = 1
  UNLISTED_TYPE_ID = 2
  LIBRARY_TYPE_ID = 3

  scope :for_language, ->(lang) { lang.to_s == 'css' ? where.not(id: LIBRARY_TYPE_ID) : all }
end
