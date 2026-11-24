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
    body = request.body.read
    return WebhookResult.respond(status: :forbidden) if user.webhook_secret.nil? || request.headers['X-Hub-Signature'] != "sha1=#{OpenSSL::HMAC.hexdigest(HMAC_DIGEST, user.webhook_secret, body)}"

    case request.headers['X-GitHub-Event']
    when 'ping'
      return WebhookResult.respond(status: :ok, body: { message: 'Webhook successfully configured.' })
    when 'push'
      return invalid_webhook_result unless valid_github_push_payload?

      changed_files = Github.info_from_push_event(params)
    when 'release'
      return WebhookResult.respond(status: :ok, body: { message: "Nothing to do on action '#{request.request_parameters[:action]}'." }) unless request.request_parameters[:action] == 'published'
      return invalid_webhook_result unless valid_github_release_payload?

      changed_files = Github.info_from_release_event(params)
    else
      return WebhookResult.respond(status: :not_acceptable)
    end

    if changed_files.empty?
      return WebhookResult.respond(status: :ok, body: { 'updated_scripts' => [], 'updated_failed' => [], message: 'No scripts found for this release.' }) if request.headers['X-GitHub-Event'] == 'release'

      return WebhookResult.respond(status: :ok, body: { 'updated_scripts' => [], 'updated_failed' => [], message: 'No commits found in this push.' })

    end

    WebhookResult.process(
      changed_files: inject_script_info(user, normalize_changed_files(changed_files)),
      repository_url: params[:repository][:clone_url],
      changelog_markup: 'markdown'
    )
  end

  def process_bitbucket_webhook(user)
    return WebhookResult.respond(status: :forbidden) if user.webhook_secret.nil? || user.webhook_secret != params[:secret]

    return WebhookResult.respond(status: :not_acceptable) if request.headers['X-Event-Key'] != 'repo:push'

    return invalid_webhook_result unless valid_bitbucket_push_payload?

    changed_files = Bitbucket.info_from_push_event(params)
    return WebhookResult.respond(status: :ok, body: { message: 'No commits found in this push.' }) if changed_files.empty?

    repo_url = "https://bitbucket.org/#{params[:repository][:full_name]}.git"

    WebhookResult.process(
      changed_files: inject_script_info(user, normalize_changed_files(changed_files)),
      repository_url: repo_url
    )
  end

  def process_gitlab_webhook(user)
    return WebhookResult.respond(status: :forbidden) if user.webhook_secret.nil? || user.webhook_secret != request.headers['X-Gitlab-Token']

    case request.headers['X-Gitlab-Event']
    when 'Push Hook'
      return invalid_webhook_result unless valid_gitlab_push_payload?

      changed_files = Gitlab.info_from_push_event(params)
    when 'Release Hook'
      return WebhookResult.respond(status: :ok, body: { message: 'Nothing to do on action delete.' }) if request.request_parameters[:action] == 'delete'
      return invalid_webhook_result unless valid_gitlab_release_payload?

      changed_files = Gitlab.info_from_release_event(params)
    else
      return WebhookResult.respond(status: :not_acceptable)
    end

    return WebhookResult.respond(status: :ok, body: { message: 'No commits found in this push.' }) if changed_files.empty?

    WebhookResult.process(
      changed_files: inject_script_info(user, normalize_changed_files(changed_files)),
      repository_url: params[:project][:git_http_url]
    )
  end

  # A sync identifier carrying a token can't be fetched by cloning the repository
  # anonymously, so its contents have to come from the URL. Additional info
  # attributes have their own sync identifiers, and a changed file can match only
  # those, so both have to be considered.
  def private_sync?(info)
    (info.scripts.to_a + info.script_attributes.to_a).any? do |record|
      record.sync_identifier&.include?('private_token')
    end
  end

  # The identifier to download a changed file from. A file that matched only an
  # additional info attribute has no scripts.
  def sync_identifier_for(info)
    (info.scripts.first || info.script_attributes.first).sync_identifier
  end

  def inject_script_info(user, changed_files)
    # Associate scripts to each file.
    changed_files.each do |_file, info|
      script_scope = user.scripts.not_deleted
      script_attribute_scope = LocalizedScriptAttribute.joins(script: :authors).where(authors: { user_id: user.id })
      prefixes, urls = info.urls.partition { |url| url.is_a?(Hash) }
      info.scripts = script_scope.where(sync_identifier: urls)
      info.script_attributes = script_attribute_scope.where(sync_identifier: urls)
      prefixes.pluck(:prefix).each do |prefix|
        info.scripts = info.scripts.or(script_scope.where('sync_identifier LIKE ?', "#{Script.sanitize_sql_like(prefix)}%"))
        info.script_attributes = info.script_attributes.or(script_attribute_scope.where('localized_script_attributes.sync_identifier LIKE ?', "#{Script.sanitize_sql_like(prefix)}%"))
      end
    end
    changed_files
  end

  def process_webhook_changes(changed_files, repo_url, changelog_markup: 'text')
    # Forget about any files that changed but are not related to scripts or attributes.
    changed_files = changed_files.select { |_filename, info| info.scripts.any? || info.script_attributes.any? }

    if changed_files.empty?
      render json: { 'updated_scripts' => [], 'updated_failed' => [], message: 'No scripts found.' }
      return
    end

    # Get the contents of the files. For assets loaded as part of a release, and for private repos, pull from the URL instead of git.
    pull_from_url, pull_from_git = changed_files.partition { |_k, v| private_sync?(v) || v.asset_url }
    pull_from_url = pull_from_url.to_h
    pull_from_git = pull_from_git.to_h

    pull_from_url.values.each do |h|
      h.content = ScriptImporter::BaseScriptImporter.download(h.asset_url || sync_identifier_for(h))
    end

    if pull_from_git.any?
      begin
        Git.get_contents(repo_url, pull_from_git.transform_values { |info| info.commit || info.ref }) do |file_path, revision, content|
          changed_files[file_path].content = content
          changed_files[file_path].revision ||= revision
        end
      rescue Git::Exception => e
        render json: { 'updated_scripts' => [], 'updated_failed' => changed_files.values.pluck(:scripts).flatten.map(&:url), message: "Could not pull contents from git: #{e}" }
        return
      end
    end

    # Apply the new contents to the DB.

    updated_scripts = []
    update_failed_scripts = []
    revision_comparison_failed = false

    changed_files.each do |_filename, info|
      contents = info.content
      info.scripts.each do |script|
        script.with_lock do
          incoming_revision = info.revision || info.commit || info.ref
          begin
            revision_order = webhook_revision_order(script, repo_url, info, incoming_revision)
          rescue Git::Exception => e
            message = "Could not determine webhook revision order for repository #{repo_url.inspect}, ref #{info.ref.inspect}, saved revision #{script.webhook_revision.inspect}, incoming revision #{incoming_revision.inspect}: #{e.message}"
            Rails.logger.warn("Script #{script.id}: #{message}")
            script.errors.add(:base, message)
            update_failed_scripts << script
            revision_comparison_failed = true
            next
          end
          # update sync type to webhook, now that we know this script is affected by it
          script.sync_type = 'webhook'
          if revision_order == :incoming_older
            if script.changed? && !script.save
              update_failed_scripts << script
            else
              updated_scripts << script
            end
            next
          end

          last_saved_sv = script.newest_saved_script_version
          sv = ScriptVersion.new(script:, code: contents, changelog: info.messages.join((changelog_markup == 'markdown') ? "\n\n" : ', '), changelog_markup:)
          sv.do_lenient_saving
          sv.calculate_all(script.description)

          same_code = last_saved_sv && sv.code == last_saved_sv.code
          # Copy previous additional infos and screenshots
          script.localized_attributes_for('additional_info').each do |la|
            sv.build_localized_attribute(la)
          end
          last_saved_sv&.attachments&.each { |a| sv.attachments << a.dup }

          script.apply_from_script_version(sv)
          script.script_versions << sv unless same_code
          if incoming_revision.present?
            script.webhook_repository = repo_url
            script.webhook_ref = info.ref
            script.webhook_previous_revision = info.previous_revision
            script.webhook_revision = incoming_revision
          end
          if script.save
            updated_scripts << script
          else
            update_failed_scripts << script
          end
        end
      end
      info.script_attributes.each do |script_attribute|
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

    result[:message] = update_failed_scripts.map { |s| "#{script_url(s)}: #{(s.errors.full_messages + s.script_versions.last&.errors&.full_messages.to_a).join(', ')}" }.join('. ') if update_failed_scripts.any?

    render json: result, status: revision_comparison_failed ? :unprocessable_content : :ok
  end

  def webhook_revision_order(script, repo_url, info, incoming_revision)
    return nil if incoming_revision.blank? || script.webhook_repository != repo_url || script.webhook_revision.blank?

    return :same if incoming_revision == script.webhook_revision

    if script.webhook_ref == info.ref
      return :incoming_newer if info.previous_revision.present? && info.previous_revision == script.webhook_revision
      return :incoming_older if incoming_revision == script.webhook_previous_revision
    end

    return nil if private_sync?(info)

    Git.revision_order(repo_url, script.webhook_revision, incoming_revision)
  end

  private

  def webhook_provider
    providers = {
      bitbucket: request.headers['X-Event-Key'],
      gitlab: request.headers['X-Gitlab-Event'],
      github: request.headers['X-GitHub-Event'],
    }.select { |_provider, event| event.present? }

    providers.keys.one? ? providers.keys.first : nil
  end

  def normalize_changed_files(changed_files)
    changed_files.transform_values { |attributes| WebhookChangedFile.from_hash(attributes) }
  end

  def invalid_webhook_result
    WebhookResult.respond(status: :bad_request, body: { message: 'Invalid webhook payload.' })
  end

  def valid_github_push_payload?
    commits = params[:commits]
    return false unless commits.nil? || commits.is_a?(Array)
    return true if commits.blank?
    return false unless webhook_hash?(params[:repository])
    return false unless webhook_values_present?(
      [:repository, :html_url], [:repository, :clone_url], [:ref], [:before], [:after]
    )

    commits.all? do |commit|
      webhook_hash?(commit) && commit[:id].present? &&
        (commit[:added].nil? || commit[:added].is_a?(Array)) &&
        (commit[:modified].nil? || commit[:modified].is_a?(Array))
    end
  end

  def valid_github_release_payload?
    webhook_hash?(params[:repository]) && webhook_hash?(params[:release]) &&
      webhook_values_present?(
        [:repository, :html_url], [:repository, :default_branch],
        [:release, :name], [:release, :tag_name]
      ) &&
      params[:release][:assets].is_a?(Array)
  end

  def valid_gitlab_push_payload?
    commits = params[:commits]
    return false unless commits.nil? || commits.is_a?(Array)
    return true if commits.blank?
    return false unless webhook_hash?(params[:repository]) && webhook_hash?(params[:project])
    return false unless webhook_values_present?(
      [:repository, :git_http_url], [:ref], [:before], [:after], [:project, :id]
    )

    commits.all? do |commit|
      webhook_hash?(commit) && commit[:id].present? &&
        (commit[:added].nil? || commit[:added].is_a?(Array)) &&
        (commit[:modified].nil? || commit[:modified].is_a?(Array))
    end
  end

  def valid_gitlab_release_payload?
    webhook_hash?(params[:project]) &&
      webhook_values_present?(
        [:project, :git_http_url], [:project, :default_branch], [:project, :id],
        [:name], [:tag]
      )
  end

  def valid_bitbucket_push_payload?
    return false unless webhook_hash?(params[:push]) && webhook_hash?(params[:repository])

    changes = params.dig(:push, :changes)
    return false unless changes.is_a?(Array)
    return true if changes.empty?

    webhook_values_present?([:repository, :full_name]) &&
      changes.all? do |change|
        webhook_hash?(change) &&
          (change[:commits].nil? || change[:commits].is_a?(Array)) &&
          change[:commits].to_a.all? do |commit|
            webhook_hash?(commit) && webhook_hash?(commit[:summary]) && commit[:hash].present?
          end
      end
  end

  def webhook_hash?(value)
    value.is_a?(Hash) || value.is_a?(ActionController::Parameters)
  end

  def webhook_values_present?(*paths)
    paths.all? { |path| webhook_value_present?(*path) }
  end

  def webhook_value_present?(*path)
    value = params
    path.each do |key|
      return false unless webhook_hash?(value) && value.key?(key)

      value = value[key]
    end
    value.present?
  end
end
