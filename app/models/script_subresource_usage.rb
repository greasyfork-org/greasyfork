class ScriptSubresourceUsage < ApplicationRecord
  belongs_to :script
  belongs_to :subresource
end
