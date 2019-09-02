require 'active_support/concern'
require 'git'

module Webhooks
  extend ActiveSupport::Concern

  HMAC_DIGEST = OpenSSL::Digest.new('sha1')

  class_methods do
    # Turns a path segment from a webhook request to a URL segment
    def urlify_webhook_path_segment(path)
      re = Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")
      return path.split('/').map{|part| URI.escape(part, re)}.join('/')
    end
  end

  def process_github_webhook(user)
    # using the secret, see if this is good
    body = request.body.read
    if user.webhook_secret.nil? || request.headers['X-Hub-Signature'] != ('sha1=' + OpenSSL::HMAC.hexdigest(HMAC_DIGEST, user.webhook_secret, body))
      head 403
      return nil, nil
    end

    if request.headers['X-GitHub-Event'] == 'ping'
      render :json => {:message => 'Webhook successfully configured.'}
      return nil, nil
    end

    if request.headers['X-GitHub-Event'] != 'push'
      head 406
      return nil, nil
    end

    if params[:commits].nil?
      render :json => {:message => 'No commits found in this push.'}
      return nil, nil
    end

    # Get a list of changed files and the commit info that goes with them.
    # We will keep all commit messages but only the most recent commit.
    changed_files = {}
    params[:commits].each do |c|
      if !c[:modified].nil?
        c[:modified].each do |m|
          changed_files[m] ||= {}
          changed_files[m][:commit] = c[:id]
          (changed_files[m][:messages] ||= []) << c[:message]
        end
      end
    end

    # construct the raw URLs from the provided info. raw URLs are in the format:
    # (repository url)/raw/(branch)/(path) OR
    # https://raw.githubusercontent.com/(user)/(repo)/(branch)/(path)
    # This will be used to find the related scripts.
    base_paths = [
      params[:repository][:url] + '/raw/' + params[:ref].split('/').last + '/', 'https://raw.githubusercontent.com/' + params[:repository][:url].split('/')[3..4].join('/') + '/' + params[:ref].split('/').last + '/'
    ]

    inject_script_info(user, changed_files, base_paths)

    return changed_files, params[:repository][:git_url]
  end

  def process_bitbucket_webhook(user)
    if user.webhook_secret.nil? || user.webhook_secret != params[:secret]
      head 403
      return nil, nil
    end

    if request.headers['X-Event-Key'] != 'repo:push'
      head 406
      return nil, nil
    end

    # Hash of commit hash to Array of commit messages
    commits = {}
    params[:push][:changes].each do |change|
      change[:commits].each do |commit| 
        (commits[commit[:hash]] ||= []) << commit[:summary][:raw]
      end
    end

    if commits.empty?
      render :json => {:message => 'No commits found in this push.'}
      return nil, nil
    end

    repo_url = "https://bitbucket.org/#{params[:repository][:full_name]}.git"
    branch = params[:push][:changes].first[:new][:name]
    base_paths = [
      "https://bitbucket.org/#{params[:repository][:full_name]}/raw/#{branch}/",
    ]

    changed_files = {}
    Git.get_files_changed(repo_url, commits.keys.uniq) do |commit, files|
      files.each do |file|
        changed_files[file] ||= {messages: []}
        changed_files[file][:commit] = commit
        changed_files[file][:messages].concat(commits[commit])
      end
    end

    inject_script_info(user, changed_files, base_paths)

    return changed_files, repo_url
  end

  def process_gitlab_webhook(user)
    if user.webhook_secret.nil? || user.webhook_secret != request.headers['X-Gitlab-Token']
      head 403
      return nil, nil
    end

    if request.headers['X-Gitlab-Event'] != 'Push Hook'
      head 406
      return nil, nil
    end

    if params[:commits].nil?
      render :json => {:message => 'No commits found in this push.'}
      return nil, nil
    end

    # Get a list of changed files and the commit info that goes with them.
    # We will keep all commit messages but only the most recent commit.
    changed_files = {}
    params[:commits].each do |c|
      if !c[:modified].nil?
        c[:modified].each do |m|
          changed_files[m] ||= {}
          changed_files[m][:commit] = c[:id]
          (changed_files[m][:messages] ||= []) << c[:message]
        end
      end
    end

    base_paths = [
      params[:repository][:git_http_url].gsub(/\.git\z/, '') + '/raw/' + params[:ref].split('/').last + '/',
    ]

    inject_script_info(user, changed_files, base_paths)

    return changed_files, params[:repository][:git_http_url]
  end


  # Adds scripts and script_attributes keys to changed_files.
  # - user
  # - changed_files - a Hash of filename to Hash
  # - base_paths - paths to add to to start of the filename to find scripts by URL
  def inject_script_info(user, changed_files, base_paths)
    # Associate scripts to each file.
    changed_files.each do |filename, info|
      urls = base_paths.map do |bp|
        bp + self.class.urlify_webhook_path_segment(filename)
      end

      # Scripts syncing code to this file
      info[:scripts] = user.scripts.not_deleted.where(sync_identifier: urls)

      # Scripts syncing additional info to this file
      info[:script_attributes] = LocalizedScriptAttribute.where(sync_identifier: urls).joins(script: :authors).where(authors: {user_id: user.id})
    end
  end

  # changed_files: Hash with keys of files names and a value of a Hash with keys:
  #   - scripts
  #   - script_attributes
  #   - commit
  #   - messages
  def process_webhook_changes(changed_files, git_url)
    # Forget about any files that changed but are not related to scripts or attributes.
    changed_files = changed_files.select{|filename, info| info[:scripts].any? || info[:script_attributes].any?}

    if changed_files.empty?
      render json: { updated_scripts: [], updated_failed: [] }
      return
    end

    # Get the contents of the files.
    Git.get_contents(git_url, Hash[changed_files.map{|filename, info| [filename, info[:commit]]}]) do |file_path, commit, content|
      changed_files[file_path][:content] = content
    end

    # Apply the new contents to the DB.

    updated_scripts = []
    update_failed_scripts = []

    changed_files.each do |filename, info|
      contents = info[:content]
      info[:scripts].each do |script|
        # update sync type to webhook, now that we know this script is affected by it
        script.script_sync_type_id = 3
        sv = script.script_versions.build(code: contents, changelog: info[:messages].join(', '))

        # Copy previous additional infos and screenshots
        last_saved_sv = script.get_newest_saved_script_version
        script.localized_attributes_for('additional_info').each do |la|
          sv.build_localized_attribute(la)
        end
        sv.screenshots = last_saved_sv.screenshots

        sv.do_lenient_saving
        sv.calculate_all(script.description)
        script.apply_from_script_version(sv)
        if script.save
          updated_scripts << script
        else
          update_failed_scripts << script
        end
      end
      info[:script_attributes].each do |script_attribute|
        script_attribute.attribute_value = contents
        if script_attribute.save
          updated_scripts << script_attribute.script
        else
          update_failed_scripts << script_attribute.script
        end
      end
    end

    render json: { updated_scripts: updated_scripts.map{ |s| script_url(s) }, updated_failed: update_failed_scripts.map{ |s| script_url(s) } }
  end

end
