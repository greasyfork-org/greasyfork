require 'open3'
class Git

	TMP_LOCATION = '/tmp/webhook'
	GIT_PATH = Rails.root.join('bin', 'git').to_s

	def self.get_contents(repo_url, file_paths_and_commits)
		# Make a directory for this repo
		directory = "#{TMP_LOCATION}/#{repo_url.gsub(/[^a-zA-Z0-9\-_]/, '')}#{Random.new.rand(1000000000)}"
		system('mkdir', '-p', TMP_LOCATION)

		begin
			content, stderr, status = Open3.capture3(GIT_PATH, 'clone', '--no-checkout', repo_url, directory)
			raise 'git clone failed' unless status.success?

			file_paths_and_commits.each do |file_path, commit|
				content, stderr, status = Open3.capture3(GIT_PATH, 'show', "#{commit}:#{file_path}", chdir: directory)
				raise stderr unless status.success?
				yield [file_path, commit, content]
			end
		ensure
			system('rm', '-rf', directory)
		end
	end

end

