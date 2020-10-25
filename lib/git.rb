require 'open3'
class Git
  TMP_LOCATION = '/tmp/webhook'.freeze
  GIT_PATH = Rails.root.join('bin/git').to_s

  def self.get_contents(repo_url, file_paths_and_commits)
    with_repo(repo_url) do |directory|
      file_paths_and_commits.each do |file_path, commit|
        content, stderr, status = Open3.capture3(GIT_PATH, 'show', "#{commit}:#{file_path}", chdir: directory)
        raise stderr unless status.success?

        yield [file_path, commit, content]
      end
    end
  end

  def self.get_files_changed(repo_url, commits)
    with_repo(repo_url) do |directory|
      commits.each do |commit|
        files, stderr, status = Open3.capture3(GIT_PATH, 'diff-tree', '--no-commit-id', '--name-only', '-r', commit, chdir: directory)
        raise stderr unless status.success?

        yield [commit, files.split("\n")]
      end
    end
  end

  def self.with_repo(repo_url)
    # Make a directory for this repo
    directory = "#{TMP_LOCATION}/#{repo_url.gsub(/[^a-zA-Z0-9\-_]/, '')}#{Random.new.rand(1_000_000_000)}"
    system('mkdir', '-p', TMP_LOCATION)
    begin
      _content, stderr, status = Open3.capture3(GIT_PATH, 'clone', '--no-checkout', repo_url, directory)
      raise "git clone failed - #{stderr}" unless status.success?

      yield(directory)
    ensure
      system('rm', '-rf', directory)
    end
  end
end
