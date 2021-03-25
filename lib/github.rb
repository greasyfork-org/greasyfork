class Github
  class << self
    # Turns a path segment from a webhook request to a URL segment
    def urlify_webhook_path_segment(path)
      path.split('/').map { |part| CGI.escape(part) }.join('/')
    end

    # Returns a Hash with keys of file names and values of a Hash with keys
    #
    # - commit
    # - messages
    # - urls
    def info_from_push_event(params)
      return {}, [] if params[:commits].nil?

      repo_url = params[:repository][:url]
      ref = params[:ref].delete_prefix('refs/heads/')

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
      repo_url = params[:repository][:html_url]
      release_name = params[:release][:name]
      ref = params[:release][:tag_name]
      default_branch = params[:repository][:default_branch]

      sync_identifiers = Script.where('sync_identifier LIKE ?', "#{Script.sanitize_sql_like(repo_url)}%").pluck(:sync_identifier)
      sync_identifiers.map { |file| file_from_root_for_url(file, repo_url) }.index_with { |file| { messages: [release_name], urls: urls_for_ref(repo_url, ref, file) + urls_for_ref(repo_url, default_branch, file), ref: ref } }
    end

    def urls_for_ref(repo_url, ref, file)
      # construct the raw URLs from the provided info. raw URLs are in the format:
      # (repository url)/raw/(branch)/(path) OR
      # https://raw.githubusercontent.com/(user)/(repo)/(branch)/(path)
      # This will be used to find the related scripts.
      [
        "#{repo_url}/raw/#{ref}/#{file}",
        "https://raw.githubusercontent.com/#{repo_url.split('/')[3..4].join('/')}/#{ref}/#{file}",
      ]
    end

    def file_from_root_for_url(url, repo_url)
      ref_pattern = %r{\A[^/]+/}
      if url.starts_with?(repo_url)
        url.sub("#{repo_url}/raw/", '').sub(ref_pattern, '')
      else
        url.sub("https://raw.githubusercontent.com/#{repo_url.split('/')[3..4].join('/')}").sub(ref_pattern, '')
      end
    end
  end
end
