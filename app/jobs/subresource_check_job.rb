class SubresourceCheckJob < ApplicationJob
  queue_as :low

  def perform(subresource)
    subresource.calculate_hashes!
  end
end
