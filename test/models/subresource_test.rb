require 'test_helper'

class SubresourceTest < ActiveSupport::TestCase
  test 'successful check' do
    subresource = Subresource.create!(url: 'https://cdn.jsdelivr.net/npm/jquery@3.2.1/dist/jquery.min.js')
    assert_changes -> { subresource.last_attempt_at } do
      assert_changes -> { subresource.last_success_at } do
        assert_changes -> { subresource.subresource_integrity_hashes.count }, from: 0, to: 4 do
          subresource.calculate_hashes!
        end
      end
    end
    assert_nil subresource.last_change_at

    assert_changes -> { subresource.last_attempt_at } do
      assert_changes -> { subresource.last_success_at } do
        assert_no_changes -> { subresource.subresource_integrity_hashes.count } do
          subresource.calculate_hashes!
        end
      end
    end
    assert_nil subresource.last_change_at
  end

  test 'failed check' do
    subresource = Subresource.create!(url: 'https://cdn.jsdelivr.net/npm/jquery@3.2.1/dist/jquery.min.js')
    URI::HTTPS.any_instance.expects(:read).raises(OpenURI::HTTPError.new(nil, nil))

    assert_changes -> { subresource.last_attempt_at } do
      assert_no_changes -> { subresource.last_success_at } do
        subresource.calculate_hashes!
      end
    end
  end

  test 'resource changes' do
    subresource = Subresource.create!(url: 'https://cdn.jsdelivr.net/npm/jquery@3.2.1/dist/jquery.min.js')
    subresource.calculate_hashes!
    subresource.subresource_integrity_hashes.update_all(integrity_hash: 'abc')

    assert_changes -> { subresource.last_attempt_at } do
      assert_changes -> { subresource.last_success_at } do
        assert_changes -> { subresource.last_change_at } do
          assert_changes -> { subresource.subresource_integrity_hashes.pluck(:integrity_hash) } do
            subresource.calculate_hashes!
          end
        end
      end
    end
  end
end
