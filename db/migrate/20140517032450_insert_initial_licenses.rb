class InsertInitialLicenses < ActiveRecord::Migration
	def change
		reversible do |dir|
			dir.up do
				execute <<-EOF
					insert into licenses (name, pattern, html, priority)
					values
						('GPL v2 or later', 'GPL( version |v)2 or any later version', '<a href="http://www.gnu.org/licenses/old-licenses/gpl-2.0.html">GPL v2</a> or later', 1000),
						('GPL v2', 'GPL v2', '<a href="http://www.gnu.org/licenses/old-licenses/gpl-2.0.html">GPL v2</a>', 500),
						('GPL v3 or later', 'GPL version 3 or any later version', '<a href="http://www.gnu.org/copyleft/gpl.html">GPL v3</a> or later', 1000),
						('GPL v3', '((GPL|General Public License) ?(v3|version 3)|http\\://www\\.gnu\\.org/copyleft/gpl\\.html)', '<a href="http://www.gnu.org/copyleft/gpl.html">GPL v3</a>', 500),
						('WTFPL', '(WTFPL(v2)?|WTF Public License)', '<a href="http://www.wtfpl.net/">WTFPL</a>', 1000),
						('MPL v2', 'MPL 2\\.0', '<a href="http://www.mozilla.org/MPL/2.0/">MPL v2</a>', 1000),
						('MIT', '^MIT', '<a href="http://opensource.org/licenses/MIT">MIT</a>', 500),
						('CC BY 3.0', 'Creative Commons Attribution 3\\.0 Unported License', '<a href="https://creativecommons.org/licenses/by/3.0/">CC BY 3.0</a>', 1000),
						('CC BY-NC-ND 3.0 US', 'http\\://creativecommons\\.org/licenses/by\\-nc\\-nd/3\\.0/us/', '<a href="http://creativecommons.org/licenses/by-nc-nd/3.0/us/">CC BY-NC-ND 3.0 US</a>', 1500),
						('Public domain', 'public domain', '<a href="http://en.wikipedia.org/wiki/Public_domain">Public domain</a>', 500),
						('CC0 1.0', '(http\\://creativecommons\\.org/publicdomain/zero/1\\.0/?|CC0 1\\.0)', '<a href="http://creativecommons.org/publicdomain/zero/1.0/">CC0 1.0</a>', 1000),
						('CC BY-NC-SA 3.0', '(http\\://creativecommons.\\org/licenses/by\\-nc\\-sa/3\\.0/|by\\-nc\\-sa 3\\.0)', '<a href="http://creativecommons.org/licenses/by-nc-sa/3.0/">CC BY-NC-SA 3.0</a>', 1000),
						('CC BY-NC 2.1 JP', 'https\\://creativecommons\\.org/licenses/by\\-nc/2\\.1/jp/', '<a href="https://creativecommons.org/licenses/by-nc/2.1/jp/">CC BY-NC 2.1 JP</a>', 1500),
						('ISC', 'http\\://opensource\\.org/licenses/ISC', '<a href="http://opensource.org/licenses/ISC">ISC</a>', 1000),
						('CC BY 4.0', 'http\\://creativecommons\\.org/licenses/by/4\\.0/', '<a href="http://creativecommons.org/licenses/by/4.0/">CC BY 4.0</a>', 1500);
				EOF
			end
			dir.down do
				execute <<-EOF
					delete from licenses
				EOF
			end
		end
	end
end
