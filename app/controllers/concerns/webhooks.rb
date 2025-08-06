require 'active_support/concern'
require 'bitbucket'
require 'git'
require 'github'
require 'gitlab'

module Webhooks
  extend ActiveSupport::Concern

  HMAC_DIGEST = OpenSSL::Digest.new('sha1')

  class_methods do
    # Turns a path segment from a webhook request to a URL segment
    def urlify_webhook_path_segment(path)
      return path.split('/').map { |part| CGI.escape(part) }.join('/')
    end
  end

  def process_github_webhook(user)
    # using the secret, see if this is good
    body = request.body.read
    if user.webhook_secret.nil? || request.headers['X-Hub-Signature'] != "sha1=#{OpenSSL::HMAC.hexdigest(HMAC_DIGEST, user.webhook_secret, body)}"
      head :forbidden
      return nil, nil
    end

    case request.headers['X-GitHub-Event']
    when 'ping'
      render json: { message: 'Webhook successfully configured.' }
      return nil, nil
    when 'push'
      changed_files = Github.info_from_push_event(params)
    when 'release'
      unless request.request_parameters[:action] == 'published'
        render json: { message: "Nothing to do on action '#{request.request_parameters[:action]}'." }
        return nil, nil
      end
      changed_files = Github.info_from_release_event(params)
    else
      head :not_acceptable
      return nil, nil
    end

    if changed_files.empty?
      if request.headers['X-GitHub-Event'] == 'release'
        render json: { 'updated_scripts' => [], 'updated_failed' => [], message: 'No scripts found for this release.' }
      else
        render json: { 'updated_scripts' => [], 'updated_failed' => [], message: 'No commits found in this push.' }
      end
      return nil, nil
    end

    inject_script_info(user, changed_files)

    return changed_files, params[:repository][:clone_url]
  rescue StandardError
    Rails.logger.error("Error processing webhook body: #{body}")
    raise
  end

  def process_bitbucket_webhook(user)
    if user.webhook_secret.nil? || user.webhook_secret != params[:secret]
      head :forbidden
      return nil, nil
    end

    if request.headers['X-Event-Key'] != 'repo:push'
      head :not_acceptable
      return nil, nil
    end

    changed_files = Bitbucket.info_from_push_event(params)
    if changed_files.empty?
      render json: { message: 'No commits found in this push.' }
      return nil, nil
    end

    repo_url = "https://bitbucket.org/#{params[:repository][:full_name]}.git"

    inject_script_info(user, changed_files)

    return changed_files, repo_url
  end

  def process_gitlab_webhook(user)
    if user.webhook_secret.nil? || user.webhook_secret != request.headers['X-Gitlab-Token']
      head :forbidden
      return nil, nil
    end

    case request.headers['X-Gitlab-Event']
    when 'Push Hook'
      changed_files = Gitlab.info_from_push_event(params)
    when 'Release Hook'
      changed_files = Gitlab.info_from_release_event(params)
    else
      head :not_acceptable
      return nil, nil
    end

    if changed_files.empty?
      render json: { message: 'No commits found in this push.' }
      return nil, nil
    end

    inject_script_info(user, changed_files)

    return changed_files, params[:project][:git_http_url]
  end

  # Adds scripts and script_attributes keys to changed_files.
  # - user
  # - changed_files - a Hash of URL to Hash
  def inject_script_info(user, changed_files)
    # Associate scripts to each file.
    changed_files.each do |_file, info|
      script_scope = user.scripts.not_deleted
      script_attribute_scope = LocalizedScriptAttribute.joins(script: :authors).where(authors: { user_id: user.id })
      prefixes, urls = info[:urls].partition { |url| url.is_a?(Hash) }
      info[:scripts] = script_scope.where(sync_identifier: urls)
      info[:script_attributes] = script_attribute_scope.where(sync_identifier: urls)
      prefixes.pluck(:prefix).each do |prefix|
        info[:scripts] = info[:scripts].or(script_scope.where('sync_identifier LIKE ?', "#{Script.sanitize_sql_like(prefix)}%"))
        info[:script_attributes] = info[:script_attributes].or(script_attribute_scope.where('localized_script_attributes.sync_identifier LIKE ?', "#{Script.sanitize_sql_like(prefix)}%"))
      end
    end
  end

  # changed_files: Hash with keys of files names and a value of a Hash with keys:
  #   - scripts
  #   - script_attributes
  #   - commit
  #   - messages
  def process_webhook_changes(changed_files, repo_url, changelog_markup: 'text')
    # Forget about any files that changed but are not related to scripts or attributes.
    changed_files = changed_files.select { |_filename, info| info[:scripts].any? || info[:script_attributes].any? }

    if changed_files.empty?
      render json: { 'updated_scripts' => [], 'updated_failed' => [], message: 'No scripts found.' }
      return
    end

    # Get the contents of the files. Some we will have to pull from the URL if it's a private repo.
    pull_from_url, pull_from_git = changed_files.partition { |_k, v| v[:scripts].any? { |s| s.sync_identifier.include?('private_token') } }
    pull_from_url = pull_from_url.to_h
    pull_from_git = pull_from_git.to_h

    pull_from_url.values.each do |h|
      h[:content] = ScriptImporter::BaseScriptImporter.download(h[:scripts].first.sync_identifier)
    end

    if pull_from_git.any?
      begin
        Git.get_contents(repo_url, pull_from_git.transform_values { |info| info[:commit] || info[:ref] }) do |file_path, _commit, content|
          changed_files[file_path][:content] = content
        end
      rescue Git::Exception => e
        render json: { 'updated_scripts' => [], 'updated_failed' => changed_files.values.pluck(:scripts).flatten.map(&:url), message: "Could not pull contents from git: #{e}" }
        return
      end
    end

    # Apply the new contents to the DB.

    updated_scripts = []
    update_failed_scripts = []

    changed_files.each do |_filename, info|
      contents = info[:content]
      info[:scripts].each do |script|
        # update sync type to webhook, now that we know this script is affected by it
        script.sync_type = 'webhook'
        sv = script.script_versions.build(code: contents, changelog: info[:messages].join((changelog_markup == 'markdown') ? "\n\n" : ', '), changelog_markup:)

        # Copy previous additional infos and screenshots
        last_saved_sv = script.newest_saved_script_version
        script.localized_attributes_for('additional_info').each do |la|
          sv.build_localized_attribute(la)
        end
        last_saved_sv.attachments.each { |a| sv.attachments << a.dup }

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

    result = {
      updated_scripts: updated_scripts.map { |s| script_url(s) },
      updated_failed: update_failed_scripts.map { |s| script_url(s) },
    }

    result[:message] = update_failed_scripts.map { |s| "#{script_url(s)}: #{(s.errors.full_messages + s.script_versions.last.errors.full_messages).join(', ')}" }.join('. ') if update_failed_scripts.any?

    render json: result
  end
end
