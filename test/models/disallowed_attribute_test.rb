require 'test_helper'

class DisallowedAttributeTest < ActiveSupport::TestCase
  test 'script attribute matches' do
    script = scripts(:one)
    assert script.valid?, script.errors.full_messages
    script.localized_attributes.where(attribute_key: 'name').update_all(attribute_value: 'SPAMMO BLAMMO')
    script.reload
    assert !script.valid?
  end

  test 'user attribute matches' do
    user = users(:one)
    assert user.valid?, user.errors.full_messages
    user.name = 'BAD USER'
    assert !user.valid?
  end
end