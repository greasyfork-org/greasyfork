class FillSummaryUrls < ActiveRecord::Migration[7.1]
  def change
    [
      ['MIT', 'https://www.tldrlegal.com/license/mit-license'],
      ['GPL-3.0', 'https://www.tldrlegal.com/license/gnu-general-public-license-v3-gpl-3'],
      ['GPL-3.0-or-later', 'https://www.tldrlegal.com/license/gnu-general-public-license-v3-gpl-3'],
      ['WTFPL', 'https://www.tldrlegal.com/license/do-wtf-you-want-to-public-license-v2-wtfpl-2-0'],
      ['Unlicense', 'https://www.tldrlegal.com/license/unlicense'],
      ['GPL-3.0-only', 'https://www.tldrlegal.com/license/gnu-general-public-license-v3-gpl-3'],
      ['Apache-2.0', 'https://www.tldrlegal.com/license/apache-license-2-0-apache-2-0'],
      ['AGPL-3.0-or-later', 'https://www.tldrlegal.com/license/gnu-affero-general-public-license-v3-agpl-3-0'],
      ['MPL-2.0', 'https://www.tldrlegal.com/license/mozilla-public-license-2-0-mpl-2'],
      ['ISC', 'https://www.tldrlegal.com/license/isc-license'],
      ['GPL-3.0+', 'https://www.tldrlegal.com/license/gnu-general-public-license-v3-gpl-3'],
      ['BSD-3-Clause', 'https://www.tldrlegal.com/license/bsd-3-clause-license-revised'],
      ['CC-BY-NC-SA-4.0', 'https://www.tldrlegal.com/license/creative-commons-attribution-noncommercial-sharealike-4-0-international-cc-by-nc-sa-4-0'],
      ['CC-BY-SA-4.0', 'https://www.tldrlegal.com/license/creative-commons-attribution-sharealike-4-0-international-cc-by-sa-4-0'],
      ['CC0-1.0', 'https://www.tldrlegal.com/license/creative-commons-cc0-1-0-universal'],
      ['GPL-2.0-only', 'https://www.tldrlegal.com/license/gnu-general-public-license-v2'],
      ['CC-BY-4.0', 'https://www.tldrlegal.com/license/creative-commons-attribution-4-0-international-cc-by-4'],
      ['AGPL-3.0-only', 'https://www.tldrlegal.com/license/gnu-affero-general-public-license-v3-agpl-3-0'],
      ['GPL-2.0-or-later', 'https://www.tldrlegal.com/license/gnu-general-public-license-v2'],
      ['GPL-2.0', 'https://www.tldrlegal.com/license/gnu-general-public-license-v2'],
      ['LGPL-3.0', 'https://www.tldrlegal.com/license/gnu-lesser-general-public-license-v3-lgpl-3'],
      ['0BSD', 'https://www.tldrlegal.com/license/bsd-0-clause-license'],
      ['Beerware', 'https://www.tldrlegal.com/license/beerware-license'],
      ['AFL-3.0', 'https://www.tldrlegal.com/license/academic-free-license-3-0-afl'],
    ].each do |code, url|
      License.find_by!(code: code).update(summary_url: url)
    end
  end
end
