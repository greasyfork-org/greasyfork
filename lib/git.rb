require 'open3'
class Git
  TMP_LOCATION = '/tmp/webhook'.freeze
  GIT_PATH = Rails.root.join('bin/git').to_s

  def self.get_contents(repo_url, file_paths_and_commits)
    with_repo(repo_url) do |directory|
      file_paths_and_commits.each do |file_path, commit|
        revision, stderr, status = Open3.capture3(GIT_PATH, 'rev-parse', '--verify', "#{commit}^{commit}", chdir: directory)
        raise Git::Exception, stderr.strip unless status.success?

        revision = revision.strip
        content, stderr, status = Open3.capture3(GIT_PATH, 'show', "#{revision}:#{file_path}", chdir: directory)
        raise Git::Exception, stderr.strip unless status.success?

        yield [file_path, revision, content]
      end
    end
  end

  def self.revision_order(repo_url, current_revision, incoming_revision)
    return :same if current_revision == incoming_revision

    with_repo(repo_url) do |directory|
      return :incoming_newer if ancestor?(directory, current_revision, incoming_revision)
      return :incoming_older if ancestor?(directory, incoming_revision, current_revision)

      :diverged
    end
  end

  def self.get_files_changed(repo_url, commits)
    with_repo(repo_url) do |directory|
      commits.each do |commit|
        if commit.blank?
          Rails.logger.warn("Blank commit provided for repo #{repo_url}")
          next
        end
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
      raise Git::Exception, "git clone of #{repo_url} failed - #{stderr}" unless status.success?

      yield(directory)
    ensure
      system('rm', '-rf', directory)
    end
  end

  def self.ancestor?(directory, older_revision, newer_revision)
    _output, stderr, status = Open3.capture3(GIT_PATH, 'merge-base', '--is-ancestor', older_revision, newer_revision, chdir: directory)
    return true if status.success?
    return false if status.exitstatus == 1

    raise Git::Exception, stderr.strip
  end
  private_class_method :ancestor?

  class Exception < StandardError
  end
end
