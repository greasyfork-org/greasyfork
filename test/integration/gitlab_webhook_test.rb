require 'test_helper'
require 'git'

class GitlabWebhookTest < ActionDispatch::IntegrationTest
  CHANGE_BODY = <<~'JSON'.freeze
    {
        "object_kind": "push",
        "event_name": "push",
        "before": "45fb6ce041fa90723b596d5cf9377b84fd447634",
        "after": "1489b5cc37a6bf1f28c33cf25bf2d2dd2965d56d",
        "ref": "refs/heads/master",
        "checkout_sha": "1489b5cc37a6bf1f28c33cf25bf2d2dd2965d56d",
        "message": null,
        "user_id": 2557057,
        "user_name": "Jason Barnabe",
        "user_username": "jason.barnabe",
        "user_email": "jason.barnabe@gmail.com",
        "user_avatar": "https://secure.gravatar.com/avatar/9385da4a3618cdc385bd49fe3d951b78?s=80&d=identicon",
        "project_id": 9515242,
        "project": {
            "id": 9515242,
            "name": "glwebhookstest",
            "description": "",
            "web_url": "https://gitlab.com/jason.barnabe/glwebhookstest",
            "avatar_url": null,
            "git_ssh_url": "git@gitlab.com:jason.barnabe/glwebhookstest.git",
            "git_http_url": "https://gitlab.com/jason.barnabe/glwebhookstest.git",
            "namespace": "jason.barnabe",
            "visibility_level": 20,
            "path_with_namespace": "jason.barnabe/glwebhookstest",
            "default_branch": "master",
            "ci_config_path": null,
            "homepage": "https://gitlab.com/jason.barnabe/glwebhookstest",
            "url": "git@gitlab.com:jason.barnabe/glwebhookstest.git",
            "ssh_url": "git@gitlab.com:jason.barnabe/glwebhookstest.git",
            "http_url": "https://gitlab.com/jason.barnabe/glwebhookstest.git"
        },
        "commits": [
            {
                "id": "1489b5cc37a6bf1f28c33cf25bf2d2dd2965d56d",
                "message": "Webhook test\n",
                "timestamp": "2018-11-20T18:40:23Z",
                "url": "https://gitlab.com/jason.barnabe/glwebhookstest/commit/1489b5cc37a6bf1f28c33cf25bf2d2dd2965d56d",
                "author": {
                    "name": "Jason Barnabe",
                    "email": "jason.barnabe@gmail.com"
                },
                "added": [],
                "modified": [
                    "test.user.js"
                ],
                "removed": []
            }
        ],
        "total_commits_count": 1,
        "repository": {
            "name": "glwebhookstest",
            "url": "git@gitlab.com:jason.barnabe/glwebhookstest.git",
            "description": "",
            "homepage": "https://gitlab.com/jason.barnabe/glwebhookstest",
            "git_http_url": "https://gitlab.com/jason.barnabe/glwebhookstest.git",
            "git_ssh_url": "git@gitlab.com:jason.barnabe/glwebhookstest.git",
            "visibility_level": 20
        }
    }
  JSON

  def webhook_request(user, secret: nil)
    post user_webhook_url(user_id: user.id),
         headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'Push Hook', 'X-Gitlab-Token' => secret || user.webhook_secret, 'Connection' => 'close', 'Host' => 'greasyfork.org', 'X-Forwarded-Proto' => 'https', 'X-Forwarded-For' => '35.231.231.98' },
         params: CHANGE_BODY
  end

  def test_webook_no_secret_match
    user = User.find(1)
    webhook_request(user, secret: 'abc123')
    assert_equal '403', response.code
  end

  def test_webook_no_script_match
    user = User.find(1)
    Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js').update!(sync_identifier: nil)
    webhook_request(user)
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => [], 'updated_failed' => [] }, JSON.parse(response.body))
  end

  def test_webhook_change
    script = Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js')
    script.update!(sync_identifier: 'https://gitlab.com/jason.barnabe/glwebhookstest/raw/master/test.user.js')
    Git.expects(:get_contents).yields('test.user.js', 'abc123', script.newest_saved_script_version.rewritten_code)
    user = User.find(1)
    webhook_request(user)
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => ['https://greasyfork.org/en/scripts/18-mb-funkey-illustrated-records-15'], 'updated_failed' => [] }, JSON.parse(response.body))
  end
end
