class ScriptCheckerBanAndDeleteJob < ApplicationJob
  queue_as :default

  def perform(script_id, script_check_results)
    begin
      script = Script.find(script_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    script_check_results = JSON.parse(script_check_results)

    moderator = User.administrators.first
    reason = script_check_results.first['public_reason']
    private_reason = ''
    related_object_id = script_check_results.first['related_object_id']
    related_object_class = script_check_results.first['related_object_class']
    private_reason = "#{related_object_class} #{related_object_id}: " if related_object_id
    private_reason += script_check_results.first['private_reason']

    script.locked = true
    script.delete_reason = reason
    script.script_delete_type_id = 2
    script.save(validate: false)

    ModeratorAction.create!(
      moderator: moderator,
      script: script,
      action: 'Delete and lock',
      reason: reason,
      private_reason: private_reason
    )
    script.ban_all_authors!(moderator: moderator, reason: reason, private_reason: private_reason)
    AdminMailer.delete_confirm(script, private_reason).deliver_later
  end
end
