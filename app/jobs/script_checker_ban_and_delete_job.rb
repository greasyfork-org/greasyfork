class ScriptCheckerBanAndDeleteJob < ApplicationJob
  queue_as :default

  def perform(script_id, script_check_results)
    begin
      script = Script.find(script_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    return if script.locked?

    script_check_results = JSON.parse(script_check_results)

    reason = script_check_results.first['public_reason']
    private_reason = ''
    related_object_id = script_check_results.first['related_object_id']
    related_object_class = script_check_results.first['related_object_class']
    private_reason = "#{related_object_class} #{related_object_id}: " if related_object_id
    private_reason += script_check_results.first['private_reason']

    script.locked = true
    script.delete_reason = reason
    script.delete_type = 'blanked'
    script.deleted_at = Time.zone.now
    script.save(validate: false)

    ModeratorAction.create!(
      automod: true,
      script:,
      action: 'Delete and lock',
      reason:,
      private_reason:
    )

    # Spare mods and established users from being banned.
    script.ban_all_authors!(automod: true, reason:, private_reason:) unless script.users.any?(&:moderator?) || script.users.any? { |u| u.created_at < 1.month.ago }

    Report.uphold_pending_reports_for(script)

    AdminMailer.delete_confirm(script, private_reason).deliver_later if script_check_results.first['notify']
  end
end
