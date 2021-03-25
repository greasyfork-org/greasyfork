class Gitlab
  class << self
    def info_from_push_event(params)
      return {}, [] if params[:commits].nil?

      repo_url = params[:repository][:git_http_url].delete_suffix('.git')
      ref = params[:ref]

      # Get a list of changed files and the commit info that goes with them.
      # We will keep all commit messages but only the most recent commit.
      changed_files = {}
      params[:commits].each do |c|
        next if c[:modified].nil?

        c[:modified].each do |m|
          changed_files[m] ||= {}
          changed_files[m][:commit] = c[:id]
          (changed_files[m][:messages] ||= []) << c[:message]
          changed_files[m][:urls] ||= urls_for_ref(repo_url, ref, m)
        end
      end

      changed_files
    end

    def info_from_release_event(params)
      repo_url = params[:project][:git_http_url].delete_suffix('.git')
      release_name = params[:name]
      ref = params[:tag]
      default_branch = params[:project][:default_branch]

      sync_identifiers = Script.where('sync_identifier LIKE ?', "#{Script.sanitize_sql_like(repo_url)}%").pluck(:sync_identifier)
      sync_identifiers.map { |file| file_from_root_for_url(file, repo_url) }.index_with { |file| { messages: [release_name], urls: urls_for_ref(repo_url, ref, file) + urls_for_ref(repo_url, default_branch, file), ref: ref } }
    end

    def urls_for_ref(repo_url, ref, file)
      [
        "#{repo_url}/raw/#{ref.split('/').last}/#{file}",
        "#{repo_url}/-/raw/#{ref.split('/').last}/#{file}",
      ]
    end

    def file_from_root_for_url(url, repo_url)
      ref_pattern = %r{\A[^/]+/}
      url.sub(repo_url, '').sub('/-', '').sub('/raw/', '').sub(ref_pattern, '')
    end
  end
end
