require 'test_helper'

class TopSitesServiceTest < ActiveSupport::TestCase
  test 'get_by_sites' do
    TopSitesService.get_by_sites(script_subset: :greasyfork)
  end

  test 'get_by_sites with locale' do
    TopSitesService.get_by_sites(script_subset: :greasyfork, locale_id: Locale.first.id)
  end

  test 'get_by_sites with user' do
    TopSitesService.get_by_sites(script_subset: :greasyfork, user_id: User.first.id)
  end

  test 'get_top_by_sites' do
    TopSitesService.get_top_by_sites(script_subset: :greasyfork)
  end

  test 'get_top_by_sites with locale' do
    TopSitesService.get_top_by_sites(script_subset: :greasyfork, locale_id: Locale.first.id)
  end

  test 'get_top_by_sites with user' do
    TopSitesService.get_top_by_sites(script_subset: :greasyfork, user_id: User.first.id)
  end

  test 'all_sites_count' do
    TopSitesService.all_sites_count
  end
end
