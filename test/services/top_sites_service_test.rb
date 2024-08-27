require 'test_helper'

class TopSitesServiceTest < ActiveSupport::TestCase
  test 'get_by_sites' do
    assert_no_error_reported do
      TopSitesService.get_by_sites(script_subset: :greasyfork)
    end
  end

  test 'get_by_sites with locale' do
    assert_no_error_reported do
      TopSitesService.get_by_sites(script_subset: :greasyfork, locale_id: Locale.first.id)
    end
  end

  test 'get_by_sites with user' do
    assert_no_error_reported do
      TopSitesService.get_by_sites(script_subset: :greasyfork, user_id: User.first.id)
    end
  end

  test 'get_top_by_sites' do
    assert_no_error_reported do
      TopSitesService.get_top_by_sites(script_subset: :greasyfork)
    end
  end

  test 'get_top_by_sites with locale' do
    assert_no_error_reported do
      TopSitesService.get_top_by_sites(script_subset: :greasyfork, locale_id: Locale.first.id)
    end
  end

  test 'get_top_by_sites with user' do
    assert_no_error_reported do
      TopSitesService.get_top_by_sites(script_subset: :greasyfork, user_id: User.first.id)
    end
  end

  test 'all_sites_count' do
    assert_no_error_reported do
      TopSitesService.all_sites_count
    end
  end

  test 'refresh!' do
    assert_no_error_reported do
      TopSitesService.refresh!
    end
  end
end
