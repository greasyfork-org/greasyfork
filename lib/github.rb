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
      return {} if params[:commits].nil?

      repo_url = params[:repository][:html_url]
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

      urls = possible_sync_urls_for_repo_url(repo_url, release: true)
      sync_identifiers = Script.where((['sync_identifier LIKE ?'] * urls.count).join(' OR '), *urls.map { |url| "#{Script.sanitize_sql_like(url)}%" }).pluck(:sync_identifier)
      sync_identifiers.map { |file| file_from_root_for_url(file, repo_url) }.index_with { |file| { messages: [release_name], urls: urls_for_ref(repo_url, ref, file, release: true) + urls_for_ref(repo_url, default_branch, file, release: true), ref: } }
    end

    def urls_for_ref(repo_url, ref, file, release: false)
      # construct the raw URLs from the provided info. This will be used to find the related scripts. Need handle spaces as %20 and +.
      urls = possible_sync_urls_for_repo_url(repo_url, release:).map do |url|
        next ["#{url}#{file.tr(' ', '+')}", "#{url}#{CGI.escape(file).tr(' ', '+').gsub('%2F', '/')}"] if url.ends_with?('latest/download/')

        ["#{url}#{ref}/#{file.tr(' ', '+')}", "#{url}#{ref}/#{CGI.escape(file).tr(' ', '+').gsub('%2F', '/')}"]
      end
      urls = urls.flatten
      (urls + urls.map { |url| url.gsub('+', '%20') }).uniq
    end

    def possible_sync_urls_for_repo_url(repo_url, release: false)
      # Raw URLs are in the format:
      # - (repository url)/raw/(branch)/(path)
      # - https://raw.githubusercontent.com/(user)/(repo)/(branch)/(path)
      # - (repository url)/releases/latest/download/(path)
      org_and_project = repo_url.split('/')[3..4].join('/')
      [
        "#{repo_url}/raw/",
        "https://raw.githubusercontent.com/#{org_and_project}/",
        ("https://github.com/#{org_and_project}/releases/latest/download/" if release),
      ].compact
    end

    def file_from_root_for_url(url, repo_url)
      ref_pattern = %r{\A[^/]+/}
      if url.starts_with?("#{repo_url}/raw/")
        url.sub("#{repo_url}/raw/", '').sub(ref_pattern, '')
      elsif url.starts_with?("#{repo_url}/releases/")
        url.sub("#{repo_url}/releases/", '').sub(ref_pattern, '').sub('download/', '')
      else
        url.sub("https://raw.githubusercontent.com/#{repo_url.split('/')[3..4].join('/')}/", '').sub(ref_pattern, '')
      end
    end
  end
end
