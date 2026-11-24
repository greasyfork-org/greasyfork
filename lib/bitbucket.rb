class Bitbucket
  class << self
    def info_from_push_event(params)
      changes = params[:push][:changes]
      return {} if changes.empty?

      commits = {}
      changes.each do |change|
        change[:commits].to_a.each do |commit|
          commit_details = (commits[commit[:hash]] ||= {
            messages: [],
            previous_revision: change[:old]&.dig(:target, :hash),
            revision: change[:new]&.dig(:target, :hash),
            ref: change[:new]&.dig(:name),
          })
          commit_details[:messages] << commit[:summary][:raw]
        end
      end

      repo_url = "https://bitbucket.org/#{params[:repository][:full_name]}"
      branch = changes.filter_map { |change| change[:new]&.dig(:name) }.first
      return {} if branch.nil?

      changed_files = {}
      Git.get_files_changed(repo_url, commits.keys.uniq) do |commit, files|
        files.each do |file|
          changed_files[file] ||= { messages: [] }
          changed_files[file][:commit] = commit
          changed_files[file][:messages].concat(commits[commit][:messages])
          changed_files[file][:previous_revision] = commits[commit][:previous_revision]
          changed_files[file][:revision] = commits[commit][:revision]
          changed_files[file][:ref] = commits[commit][:ref]
          changed_files[file][:urls] ||= urls_for_ref(repo_url, branch, file)
        end
      end

      changed_files
    end

    def urls_for_ref(repo_url, ref, file)
      [
        "#{repo_url}/raw/#{ref}/#{file}",
      ]
    end
  end
end
