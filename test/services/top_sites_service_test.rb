require 'test_helper'

class TopSitesServiceTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
  end

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

  test 'get_by_sites filters all-sites stats by subset' do
    scripts(:one).update_columns(sensitive: true, daily_installs: 7)
    scripts(:two).update_columns(sensitive: false, daily_installs: 11)

    greasy_scripts = Script.where(script_type: :public, delete_type: nil, sensitive: false).for_all_sites
    sleazy_scripts = Script.where(script_type: :public, delete_type: nil, sensitive: true).for_all_sites
    greasy_expected = { installs: greasy_scripts.sum(:daily_installs), scripts: greasy_scripts.count }
    sleazy_expected = { installs: sleazy_scripts.sum(:daily_installs), scripts: sleazy_scripts.count }

    assert_predicate greasy_expected[:installs], :positive?
    assert_predicate greasy_expected[:scripts], :positive?
    assert_predicate sleazy_expected[:installs], :positive?
    assert_predicate sleazy_expected[:scripts], :positive?
    assert_equal greasy_expected, TopSitesService.get_by_sites(script_subset: :greasyfork, force: true).fetch(nil)
    assert_equal sleazy_expected, TopSitesService.get_by_sites(script_subset: :sleazyfork, force: true).fetch(nil)
  end

  test 'get_by_sites filters all-sites stats by locale' do
    locale = locales(:french)
    scripts(:synced_and_localized).update_column(:daily_installs, 13)
    script_ids = LocalizedScriptAttribute.where(locale:).distinct.select(:script_id)
    scripts = Script.where(id: script_ids, script_type: :public, delete_type: nil, sensitive: false).for_all_sites
    expected = { installs: scripts.sum(:daily_installs), scripts: scripts.count }

    assert_predicate expected[:installs], :positive?
    assert_predicate expected[:scripts], :positive?
    assert_equal expected, TopSitesService.get_by_sites(script_subset: :greasyfork, locale_id: locale.id, force: true).fetch(nil)
  end

  test 'get_by_sites filters all-sites stats by user' do
    user = users(:consumer)
    scripts(:derivative_with_same_name).update_column(:daily_installs, 17)
    scripts = user.scripts.where(script_type: :public, delete_type: nil, sensitive: false).for_all_sites
    expected = { installs: scripts.sum(:daily_installs), scripts: scripts.count }

    assert_predicate expected[:installs], :positive?
    assert_predicate expected[:scripts], :positive?
    assert_equal expected, TopSitesService.get_by_sites(script_subset: :greasyfork, user_id: user.id, force: true).fetch(nil)
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
