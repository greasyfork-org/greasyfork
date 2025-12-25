class LibraryUsage < ApplicationRecord
  belongs_to :script
  belongs_to :library_script, class_name: 'Script'
end
