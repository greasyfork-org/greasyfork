require 'test_helper'

class DisallowedAttributeTest < ActiveSupport::TestCase
  test 'regular attribute matches' do
    script = scripts(:one)
    assert script.valid?
    script.localized_attributes.where(attribute_key: 'name').update_all(attribute_value: 'SPAMMO BLAMMO')
    script.reload
    assert !script.valid?
  end
end