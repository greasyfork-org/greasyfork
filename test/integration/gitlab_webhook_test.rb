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

  RELEASE_BODY = <<~JSON.freeze
    {
        "id": 2608554,
        "created_at": "2021-03-23 02:39:16 UTC",
        "description": "",
        "name": "v0.0.1",
        "released_at": "2021-03-23 02:39:16 UTC",
        "tag": "v0.0.1",
        "object_kind": "release",
        "project": {
            "id": 9515242,
            "name": "glwebhookstest",
            "description": "",
            "web_url": "https://gitlab.com/jason.barnabe/glwebhookstest",
            "avatar_url": null,
            "git_ssh_url": "git@gitlab.com:jason.barnabe/glwebhookstest.git",
            "git_http_url": "https://gitlab.com/jason.barnabe/glwebhookstest.git",
            "namespace": "Jason Barnabe",
            "visibility_level": 20,
            "path_with_namespace": "jason.barnabe/glwebhookstest",
            "default_branch": "master",
            "ci_config_path": null,
            "homepage": "https://gitlab.com/jason.barnabe/glwebhookstest",
            "url": "git@gitlab.com:jason.barnabe/glwebhookstest.git",
            "ssh_url": "git@gitlab.com:jason.barnabe/glwebhookstest.git",
            "http_url": "https://gitlab.com/jason.barnabe/glwebhookstest.git"
        },
        "url": "https://gitlab.com/jason.barnabe/glwebhookstest/-/releases/v0.0.1",
        "action": "create",
        "assets": {
            "count": 4,
            "links": [],
            "sources": [
                {
                    "format": "zip",
                    "url": "https://gitlab.com/jason.barnabe/glwebhookstest/-/archive/v0.0.1/glwebhookstest-v0.0.1.zip"
                },
                {
                    "format": "tar.gz",
                    "url": "https://gitlab.com/jason.barnabe/glwebhookstest/-/archive/v0.0.1/glwebhookstest-v0.0.1.tar.gz"
                },
                {
                    "format": "tar.bz2",
                    "url": "https://gitlab.com/jason.barnabe/glwebhookstest/-/archive/v0.0.1/glwebhookstest-v0.0.1.tar.bz2"
                },
                {
                    "format": "tar",
                    "url": "https://gitlab.com/jason.barnabe/glwebhookstest/-/archive/v0.0.1/glwebhookstest-v0.0.1.tar"
                }
            ]
        },
        "commit": {
            "id": "64bd28f57a4853026a5a128ac446a8252bef4f7d",
            "message": "Update test.user.js",
            "title": "Update test.user.js",
            "timestamp": "2021-03-23T02:22:03+00:00",
            "url": "https://gitlab.com/jason.barnabe/glwebhookstest/-/commit/64bd28f57a4853026a5a128ac446a8252bef4f7d",
            "author": {
                "name": "Jason Barnabe",
                "email": "jason.barnabe@gmail.com"
            }
        }
    }
  JSON

  def push_webhook_request(user, secret: nil)
    post user_webhook_url(user_id: user.id),
         headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'Push Hook', 'X-Gitlab-Token' => secret || user.webhook_secret, 'Connection' => 'close', 'Host' => 'greasyfork.org', 'X-Forwarded-Proto' => 'https', 'X-Forwarded-For' => '35.231.231.98' },
         params: CHANGE_BODY
  end

  def release_webhook_request(user, secret: nil)
    post user_webhook_url(user_id: user.id),
         headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'Release Hook', 'X-Gitlab-Token' => secret || user.webhook_secret, 'Connection' => 'close', 'Host' => 'greasyfork.org', 'X-Forwarded-Proto' => 'https', 'X-Forwarded-For' => '35.231.231.98' },
         params: RELEASE_BODY
  end

  def test_webook_no_secret_match
    user = User.find(1)
    push_webhook_request(user, secret: 'abc123')
    assert_equal '403', response.code
  end

  def test_webook_no_script_match
    user = User.find(1)
    Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js').update!(sync_identifier: nil)
    push_webhook_request(user)
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => [], 'updated_failed' => [] }, JSON.parse(response.body))
  end

  def test_webhook_change
    script = Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js')
    script.update!(sync_identifier: 'https://gitlab.com/jason.barnabe/glwebhookstest/raw/master/test.user.js')
    Git.expects(:get_contents).with('https://gitlab.com/jason.barnabe/glwebhookstest.git', { 'test.user.js' => '1489b5cc37a6bf1f28c33cf25bf2d2dd2965d56d' }).yields('test.user.js', 'abc123', script.newest_saved_script_version.rewritten_code)
    user = User.find(1)
    push_webhook_request(user)
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => ['https://greasyfork.org/en/scripts/18-mb-funkey-illustrated-records-15'], 'updated_failed' => [] }, JSON.parse(response.body))
  end

  def test_webhook_release
    script = Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js')
    script.update!(sync_identifier: 'https://gitlab.com/jason.barnabe/glwebhookstest/raw/master/test.user.js')
    Git.expects(:get_contents).with('https://gitlab.com/jason.barnabe/glwebhookstest.git', { 'test.user.js' => 'v0.0.1' }).yields('test.user.js', 'abc123', script.newest_saved_script_version.rewritten_code)
    user = User.find(1)
    release_webhook_request(user)
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => ['https://greasyfork.org/en/scripts/18-mb-funkey-illustrated-records-15'], 'updated_failed' => [] }, JSON.parse(response.body))
  end
end
