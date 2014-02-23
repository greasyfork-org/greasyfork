class AddGreasyForkLibrariesToAllowedRequires < ActiveRecord::Migration
	def change
		execute "INSERT INTO allowed_requires (pattern, name, url) VALUES ('^https:\\\\/\\\\/greasyfork\\\\.org\\\\/libraries\\\\/.*', 'Greasy-Fork-hosted libraries on https://greasyfork.org/libraries/', 'https://github.com/JasonBarnabe/greasyfork/tree/master/public/libraries')"
	end
end
