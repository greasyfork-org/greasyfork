class Bitbucket
  class << self
    def info_from_push_event(params)
      return {}, [] if params[:push][:changes].empty?

      commits = {}
      params[:push][:changes].each do |change|
        change[:commits].each do |commit|
          (commits[commit[:hash]] ||= []) << commit[:summary][:raw]
        end
      end

      repo_url = "https://bitbucket.org/#{params[:repository][:full_name]}"
      branch = params[:push][:changes].first[:new][:name]

      changed_files = {}
      Git.get_files_changed(repo_url, commits.keys.uniq) do |commit, files|
        files.each do |file|
          changed_files[file] ||= { messages: [] }
          changed_files[file][:commit] = commit
          changed_files[file][:messages].concat(commits[commit])
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
