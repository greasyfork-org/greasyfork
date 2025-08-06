require 'test_helper'
require 'git'

class GithubWebhookTest < ActionDispatch::IntegrationTest
  RELEASE_BODY = <<~JSON.freeze
    {"action":"published","release":{"url":"https://api.github.com/repos/JasonBarnabe/webhooktest/releases/39744248","assets_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/releases/39744248/assets","upload_url":"https://uploads.github.com/repos/JasonBarnabe/webhooktest/releases/39744248/assets{?name,label}","html_url":"https://github.com/JasonBarnabe/webhooktest/releases/tag/v0.0.1","id":39744248,"author":{"login":"JasonBarnabe","id":583995,"node_id":"MDQ6VXNlcjU4Mzk5NQ==","avatar_url":"https://avatars.githubusercontent.com/u/583995?v=4","gravatar_id":"","url":"https://api.github.com/users/JasonBarnabe","html_url":"https://github.com/JasonBarnabe","followers_url":"https://api.github.com/users/JasonBarnabe/followers","following_url":"https://api.github.com/users/JasonBarnabe/following{/other_user}","gists_url":"https://api.github.com/users/JasonBarnabe/gists{/gist_id}","starred_url":"https://api.github.com/users/JasonBarnabe/starred{/owner}{/repo}","subscriptions_url":"https://api.github.com/users/JasonBarnabe/subscriptions","organizations_url":"https://api.github.com/users/JasonBarnabe/orgs","repos_url":"https://api.github.com/users/JasonBarnabe/repos","events_url":"https://api.github.com/users/JasonBarnabe/events{/privacy}","received_events_url":"https://api.github.com/users/JasonBarnabe/received_events","type":"User","site_admin":false},"node_id":"MDc6UmVsZWFzZTM5NzQ0MjQ4","tag_name":"v0.0.1","target_commitish":"master","name":"v0.0.1 title","draft":false,"prerelease":false,"created_at":"2019-11-12T00:32:11Z","published_at":"2021-03-13T00:28:06Z","assets":[],"tarball_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/tarball/v0.0.1","zipball_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/zipball/v0.0.1","body":"test description"},"repository":{"id":20602128,"node_id":"MDEwOlJlcG9zaXRvcnkyMDYwMjEyOA==","name":"webhooktest","full_name":"JasonBarnabe/webhooktest","private":false,"owner":{"login":"JasonBarnabe","id":583995,"node_id":"MDQ6VXNlcjU4Mzk5NQ==","avatar_url":"https://avatars.githubusercontent.com/u/583995?v=4","gravatar_id":"","url":"https://api.github.com/users/JasonBarnabe","html_url":"https://github.com/JasonBarnabe","followers_url":"https://api.github.com/users/JasonBarnabe/followers","following_url":"https://api.github.com/users/JasonBarnabe/following{/other_user}","gists_url":"https://api.github.com/users/JasonBarnabe/gists{/gist_id}","starred_url":"https://api.github.com/users/JasonBarnabe/starred{/owner}{/repo}","subscriptions_url":"https://api.github.com/users/JasonBarnabe/subscriptions","organizations_url":"https://api.github.com/users/JasonBarnabe/orgs","repos_url":"https://api.github.com/users/JasonBarnabe/repos","events_url":"https://api.github.com/users/JasonBarnabe/events{/privacy}","received_events_url":"https://api.github.com/users/JasonBarnabe/received_events","type":"User","site_admin":false},"html_url":"https://github.com/JasonBarnabe/webhooktest","description":"Test repository for Greasy Fork/GitHub webhook","fork":false,"url":"https://api.github.com/repos/JasonBarnabe/webhooktest","forks_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/forks","keys_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/keys{/key_id}","collaborators_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/collaborators{/collaborator}","teams_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/teams","hooks_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/hooks","issue_events_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/issues/events{/number}","events_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/events","assignees_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/assignees{/user}","branches_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/branches{/branch}","tags_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/tags","blobs_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/git/blobs{/sha}","git_tags_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/git/tags{/sha}","git_refs_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/git/refs{/sha}","trees_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/git/trees{/sha}","statuses_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/statuses/{sha}","languages_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/languages","stargazers_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/stargazers","contributors_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/contributors","subscribers_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/subscribers","subscription_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/subscription","commits_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/commits{/sha}","git_commits_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/git/commits{/sha}","comments_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/comments{/number}","issue_comment_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/issues/comments{/number}","contents_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/contents/{+path}","compare_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/compare/{base}...{head}","merges_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/merges","archive_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/{archive_format}{/ref}","downloads_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/downloads","issues_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/issues{/number}","pulls_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/pulls{/number}","milestones_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/milestones{/number}","notifications_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/notifications{?since,all,participating}","labels_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/labels{/name}","releases_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/releases{/id}","deployments_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/deployments","created_at":"2014-06-07T20:31:50Z","updated_at":"2019-11-12T00:32:13Z","pushed_at":"2021-03-13T00:28:06Z","git_url":"git://github.com/JasonBarnabe/webhooktest.git","ssh_url":"git@github.com:JasonBarnabe/webhooktest.git","clone_url":"https://github.com/JasonBarnabe/webhooktest.git","svn_url":"https://github.com/JasonBarnabe/webhooktest","homepage":null,"size":43,"stargazers_count":0,"watchers_count":0,"language":"JavaScript","has_issues":true,"has_projects":true,"has_downloads":true,"has_wiki":true,"has_pages":false,"forks_count":0,"mirror_url":null,"archived":false,"disabled":false,"open_issues_count":0,"license":null,"forks":0,"open_issues":0,"watchers":0,"default_branch":"master"},"sender":{"login":"JasonBarnabe","id":583995,"node_id":"MDQ6VXNlcjU4Mzk5NQ==","avatar_url":"https://avatars.githubusercontent.com/u/583995?v=4","gravatar_id":"","url":"https://api.github.com/users/JasonBarnabe","html_url":"https://github.com/JasonBarnabe","followers_url":"https://api.github.com/users/JasonBarnabe/followers","following_url":"https://api.github.com/users/JasonBarnabe/following{/other_user}","gists_url":"https://api.github.com/users/JasonBarnabe/gists{/gist_id}","starred_url":"https://api.github.com/users/JasonBarnabe/starred{/owner}{/repo}","subscriptions_url":"https://api.github.com/users/JasonBarnabe/subscriptions","organizations_url":"https://api.github.com/users/JasonBarnabe/orgs","repos_url":"https://api.github.com/users/JasonBarnabe/repos","events_url":"https://api.github.com/users/JasonBarnabe/events{/privacy}","received_events_url":"https://api.github.com/users/JasonBarnabe/received_events","type":"User","site_admin":false}}
  JSON

  def push_body(path: 'test.user.js')
    <<~JSON.freeze
      {"ref":"refs/heads/master","before":"2030837ab1ae20547c20bdb4389d8ce3fca5d9e4","after":"7e1817e12430e179c0103c658018168f081336af","created":false,"deleted":false,"forced":false,"base_ref":null,"compare":"https://github.com/JasonBarnabe/webhooktest/compare/2030837ab1ae...7e1817e12430","commits":[{"id":"7e1817e12430e179c0103c658018168f081336af","tree_id":"37fe20e4a0995a5499bf7266eae0ec082aa1e354","distinct":true,"message":"test for test","timestamp":"2018-11-03T12:02:02-05:00","url":"https://github.com/JasonBarnabe/webhooktest/commit/7e1817e12430e179c0103c658018168f081336af","author":{"name":"Jason Barnabe","email":"jason.barnabe@gmail.com","username":"JasonBarnabe"},"committer":{"name":"GitHub","email":"noreply@github.com","username":"web-flow"},"added":[],"removed":[],"modified":["#{path}"]}],"head_commit":{"id":"7e1817e12430e179c0103c658018168f081336af","tree_id":"37fe20e4a0995a5499bf7266eae0ec082aa1e354","distinct":true,"message":"test for test","timestamp":"2018-11-03T12:02:02-05:00","url":"https://github.com/JasonBarnabe/webhooktest/commit/7e1817e12430e179c0103c658018168f081336af","author":{"name":"Jason Barnabe","email":"jason.barnabe@gmail.com","username":"JasonBarnabe"},"committer":{"name":"GitHub","email":"noreply@github.com","username":"web-flow"},"added":[],"removed":[],"modified":["#{path}"]},"repository":{"id":20602128,"node_id":"MDEwOlJlcG9zaXRvcnkyMDYwMjEyOA==","name":"webhooktest","full_name":"JasonBarnabe/webhooktest","private":false,"owner":{"name":"JasonBarnabe","email":"jason.barnabe@gmail.com","login":"JasonBarnabe","id":583995,"node_id":"MDQ6VXNlcjU4Mzk5NQ==","avatar_url":"https://avatars3.githubusercontent.com/u/583995?v=4","gravatar_id":"","url":"https://api.github.com/users/JasonBarnabe","html_url":"https://github.com/JasonBarnabe","followers_url":"https://api.github.com/users/JasonBarnabe/followers","following_url":"https://api.github.com/users/JasonBarnabe/following{/other_user}","gists_url":"https://api.github.com/users/JasonBarnabe/gists{/gist_id}","starred_url":"https://api.github.com/users/JasonBarnabe/starred{/owner}{/repo}","subscriptions_url":"https://api.github.com/users/JasonBarnabe/subscriptions","organizations_url":"https://api.github.com/users/JasonBarnabe/orgs","repos_url":"https://api.github.com/users/JasonBarnabe/repos","events_url":"https://api.github.com/users/JasonBarnabe/events{/privacy}","received_events_url":"https://api.github.com/users/JasonBarnabe/received_events","type":"User","site_admin":false},"html_url":"https://github.com/JasonBarnabe/webhooktest","description":"Test repository for Greasy Fork/GitHub webhook","fork":false,"url":"https://github.com/JasonBarnabe/webhooktest","forks_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/forks","keys_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/keys{/key_id}","collaborators_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/collaborators{/collaborator}","teams_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/teams","hooks_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/hooks","issue_events_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/issues/events{/number}","events_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/events","assignees_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/assignees{/user}","branches_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/branches{/branch}","tags_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/tags","blobs_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/git/blobs{/sha}","git_tags_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/git/tags{/sha}","git_refs_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/git/refs{/sha}","trees_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/git/trees{/sha}","statuses_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/statuses/{sha}","languages_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/languages","stargazers_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/stargazers","contributors_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/contributors","subscribers_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/subscribers","subscription_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/subscription","commits_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/commits{/sha}","git_commits_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/git/commits{/sha}","comments_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/comments{/number}","issue_comment_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/issues/comments{/number}","contents_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/contents/{+path}","compare_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/compare/{base}...{head}","merges_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/merges","archive_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/{archive_format}{/ref}","downloads_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/downloads","issues_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/issues{/number}","pulls_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/pulls{/number}","milestones_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/milestones{/number}","notifications_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/notifications{?since,all,participating}","labels_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/labels{/name}","releases_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/releases{/id}","deployments_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/deployments","created_at":1402173110,"updated_at":"2017-04-02T01:29:53Z","pushed_at":1541264523,"git_url":"git://github.com/JasonBarnabe/webhooktest.git","ssh_url":"git@github.com:JasonBarnabe/webhooktest.git","clone_url":"https://github.com/JasonBarnabe/webhooktest.git","svn_url":"https://github.com/JasonBarnabe/webhooktest","homepage":null,"size":55,"stargazers_count":0,"watchers_count":0,"language":"JavaScript","has_issues":true,"has_projects":true,"has_downloads":true,"has_wiki":true,"has_pages":false,"forks_count":0,"mirror_url":null,"archived":false,"open_issues_count":0,"license":null,"forks":0,"open_issues":0,"watchers":0,"default_branch":"master","stargazers":0,"master_branch":"master"},"pusher":{"name":"JasonBarnabe","email":"jason.barnabe@gmail.com"},"sender":{"login":"JasonBarnabe","id":583995,"node_id":"MDQ6VXNlcjU4Mzk5NQ==","avatar_url":"https://avatars3.githubusercontent.com/u/583995?v=4","gravatar_id":"","url":"https://api.github.com/users/JasonBarnabe","html_url":"https://github.com/JasonBarnabe","followers_url":"https://api.github.com/users/JasonBarnabe/followers","following_url":"https://api.github.com/users/JasonBarnabe/following{/other_user}","gists_url":"https://api.github.com/users/JasonBarnabe/gists{/gist_id}","starred_url":"https://api.github.com/users/JasonBarnabe/starred{/owner}{/repo}","subscriptions_url":"https://api.github.com/users/JasonBarnabe/subscriptions","organizations_url":"https://api.github.com/users/JasonBarnabe/orgs","repos_url":"https://api.github.com/users/JasonBarnabe/repos","events_url":"https://api.github.com/users/JasonBarnabe/events{/privacy}","received_events_url":"https://api.github.com/users/JasonBarnabe/received_events","type":"User","site_admin":false}}
    JSON
  end

  def push_body_with_no_commits
    <<~JSON.freeze
      {"ref":"refs/heads/master","before":"2030837ab1ae20547c20bdb4389d8ce3fca5d9e4","after":"7e1817e12430e179c0103c658018168f081336af","created":false,"deleted":false,"forced":false,"base_ref":null,"compare":"https://github.com/JasonBarnabe/webhooktest/compare/2030837ab1ae...7e1817e12430","head_commit":{"id":"7e1817e12430e179c0103c658018168f081336af","tree_id":"37fe20e4a0995a5499bf7266eae0ec082aa1e354","distinct":true,"message":"test for test","timestamp":"2018-11-03T12:02:02-05:00","url":"https://github.com/JasonBarnabe/webhooktest/commit/7e1817e12430e179c0103c658018168f081336af","author":{"name":"Jason Barnabe","email":"jason.barnabe@gmail.com","username":"JasonBarnabe"},"committer":{"name":"GitHub","email":"noreply@github.com","username":"web-flow"},"added":[],"removed":[],"modified":["#{path}"]},"repository":{"id":20602128,"node_id":"MDEwOlJlcG9zaXRvcnkyMDYwMjEyOA==","name":"webhooktest","full_name":"JasonBarnabe/webhooktest","private":false,"owner":{"name":"JasonBarnabe","email":"jason.barnabe@gmail.com","login":"JasonBarnabe","id":583995,"node_id":"MDQ6VXNlcjU4Mzk5NQ==","avatar_url":"https://avatars3.githubusercontent.com/u/583995?v=4","gravatar_id":"","url":"https://api.github.com/users/JasonBarnabe","html_url":"https://github.com/JasonBarnabe","followers_url":"https://api.github.com/users/JasonBarnabe/followers","following_url":"https://api.github.com/users/JasonBarnabe/following{/other_user}","gists_url":"https://api.github.com/users/JasonBarnabe/gists{/gist_id}","starred_url":"https://api.github.com/users/JasonBarnabe/starred{/owner}{/repo}","subscriptions_url":"https://api.github.com/users/JasonBarnabe/subscriptions","organizations_url":"https://api.github.com/users/JasonBarnabe/orgs","repos_url":"https://api.github.com/users/JasonBarnabe/repos","events_url":"https://api.github.com/users/JasonBarnabe/events{/privacy}","received_events_url":"https://api.github.com/users/JasonBarnabe/received_events","type":"User","site_admin":false},"html_url":"https://github.com/JasonBarnabe/webhooktest","description":"Test repository for Greasy Fork/GitHub webhook","fork":false,"url":"https://github.com/JasonBarnabe/webhooktest","forks_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/forks","keys_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/keys{/key_id}","collaborators_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/collaborators{/collaborator}","teams_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/teams","hooks_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/hooks","issue_events_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/issues/events{/number}","events_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/events","assignees_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/assignees{/user}","branches_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/branches{/branch}","tags_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/tags","blobs_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/git/blobs{/sha}","git_tags_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/git/tags{/sha}","git_refs_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/git/refs{/sha}","trees_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/git/trees{/sha}","statuses_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/statuses/{sha}","languages_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/languages","stargazers_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/stargazers","contributors_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/contributors","subscribers_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/subscribers","subscription_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/subscription","commits_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/commits{/sha}","git_commits_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/git/commits{/sha}","comments_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/comments{/number}","issue_comment_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/issues/comments{/number}","contents_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/contents/{+path}","compare_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/compare/{base}...{head}","merges_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/merges","archive_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/{archive_format}{/ref}","downloads_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/downloads","issues_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/issues{/number}","pulls_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/pulls{/number}","milestones_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/milestones{/number}","notifications_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/notifications{?since,all,participating}","labels_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/labels{/name}","releases_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/releases{/id}","deployments_url":"https://api.github.com/repos/JasonBarnabe/webhooktest/deployments","created_at":1402173110,"updated_at":"2017-04-02T01:29:53Z","pushed_at":1541264523,"git_url":"git://github.com/JasonBarnabe/webhooktest.git","ssh_url":"git@github.com:JasonBarnabe/webhooktest.git","clone_url":"https://github.com/JasonBarnabe/webhooktest.git","svn_url":"https://github.com/JasonBarnabe/webhooktest","homepage":null,"size":55,"stargazers_count":0,"watchers_count":0,"language":"JavaScript","has_issues":true,"has_projects":true,"has_downloads":true,"has_wiki":true,"has_pages":false,"forks_count":0,"mirror_url":null,"archived":false,"open_issues_count":0,"license":null,"forks":0,"open_issues":0,"watchers":0,"default_branch":"master","stargazers":0,"master_branch":"master"},"pusher":{"name":"JasonBarnabe","email":"jason.barnabe@gmail.com"},"sender":{"login":"JasonBarnabe","id":583995,"node_id":"MDQ6VXNlcjU4Mzk5NQ==","avatar_url":"https://avatars3.githubusercontent.com/u/583995?v=4","gravatar_id":"","url":"https://api.github.com/users/JasonBarnabe","html_url":"https://github.com/JasonBarnabe","followers_url":"https://api.github.com/users/JasonBarnabe/followers","following_url":"https://api.github.com/users/JasonBarnabe/following{/other_user}","gists_url":"https://api.github.com/users/JasonBarnabe/gists{/gist_id}","starred_url":"https://api.github.com/users/JasonBarnabe/starred{/owner}{/repo}","subscriptions_url":"https://api.github.com/users/JasonBarnabe/subscriptions","organizations_url":"https://api.github.com/users/JasonBarnabe/orgs","repos_url":"https://api.github.com/users/JasonBarnabe/repos","events_url":"https://api.github.com/users/JasonBarnabe/events{/privacy}","received_events_url":"https://api.github.com/users/JasonBarnabe/received_events","type":"User","site_admin":false}}
    JSON
  end

  def push_webhook_request(user, path: 'test.user.js', secret: nil)
    body = push_body(path:).strip
    signature = OpenSSL::HMAC.hexdigest(UsersController::HMAC_DIGEST, secret || user.webhook_secret, body)
    post user_webhook_url(user_id: user.id),
         headers: { 'Host' => 'greasyfork.org', 'Accept' => '*/*', 'User-Agent' => 'GitHub-Hookshot/8e03811', 'X-GitHub-Event' => 'push', 'X-GitHub-Delivery' => '2fdd0ba2-df8a-11e8-9fba-09ae25713944', 'content-type' => 'application/json', 'X-Hub-Signature' => "sha1=#{signature}", 'Content-Length' => body.bytesize, 'X-Forwarded-Proto' => 'https', 'X-Forwarded-For' => '192.30.252.44' },
         params: body
  end

  def push_webhook_request_with_no_commits(user, secret: nil)
    body = push_body_with_no_commits.strip
    signature = OpenSSL::HMAC.hexdigest(UsersController::HMAC_DIGEST, secret || user.webhook_secret, body)
    post user_webhook_url(user_id: user.id),
         headers: { 'Host' => 'greasyfork.org', 'Accept' => '*/*', 'User-Agent' => 'GitHub-Hookshot/8e03811', 'X-GitHub-Event' => 'push', 'X-GitHub-Delivery' => '2fdd0ba2-df8a-11e8-9fba-09ae25713944', 'content-type' => 'application/json', 'X-Hub-Signature' => "sha1=#{signature}", 'Content-Length' => body.bytesize, 'X-Forwarded-Proto' => 'https', 'X-Forwarded-For' => '192.30.252.44' },
         params: body
  end

  def release_webhook_request(user, secret: nil)
    body = RELEASE_BODY.strip
    signature = OpenSSL::HMAC.hexdigest(UsersController::HMAC_DIGEST, secret || user.webhook_secret, body)
    post user_webhook_url(user_id: user.id),
         headers: { 'Host' => 'greasyfork.org', 'User-Agent' => 'GitHub-Hookshot/3a6e330', 'Content-Length' => body.bytesize, 'Accept' => '*/*', 'Connection' => 'close', 'Content-Type' => 'application/json', 'X-Github-Delivery' => 'fb2d83a0-8392-11eb-9507-b40437409f4e', 'X-Github-Event' => 'release', 'X-Github-Hook-Id' => '2385073', 'X-Github-Hook-Installation-Target-Id' => '20602128', 'X-Github-Hook-Installation-Target-Type' => 'repository', 'X-Hub-Signature' => "sha1=#{signature}", 'X-Forwarded-Proto' => 'https' },
         params: body
  end

  def test_webhook_no_secret_match
    user = User.find(1)
    push_webhook_request(user, secret: 'abc123')
    assert_equal '403', response.code
  end

  def test_webhook_no_script_match
    user = User.find(1)
    Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js').update!(sync_identifier: nil)
    push_webhook_request(user)
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => [], 'updated_failed' => [], 'message' => 'No scripts found.' }, response.parsed_body)
  end

  def test_webhook_push
    script = Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js')
    Git.expects(:get_contents).with('https://github.com/JasonBarnabe/webhooktest.git', { 'test.user.js' => '7e1817e12430e179c0103c658018168f081336af' }).yields('test.user.js', 'abc123', script.newest_saved_script_version.rewritten_code)
    user = User.find(1)
    push_webhook_request(user)
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => ['https://greasyfork.org/en/scripts/18-mb-funkey-illustrated-records-15'], 'updated_failed' => [] }, response.parsed_body)
  end

  def test_webhook_push_with_no_commits
    user = User.find(1)
    push_webhook_request_with_no_commits(user)
    assert_equal '200', response.code
  end

  def test_webhook_push_non_ascii_filename_with_encoded_webhook
    script = scripts(:one)
    script.update!(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/TamperMonkey/BIT-%E8%A1%A5%E8%B6%B3%E9%A1%B5%E9%9D%A2%E6%A0%87%E9%A2%98.user.js')
    Git.expects(:get_contents).with('https://github.com/JasonBarnabe/webhooktest.git', { 'TamperMonkey/BIT-%E8%A1%A5%E8%B6%B3%E9%A1%B5%E9%9D%A2%E6%A0%87%E9%A2%98.user.js' => '7e1817e12430e179c0103c658018168f081336af' }).yields('TamperMonkey/BIT-%E8%A1%A5%E8%B6%B3%E9%A1%B5%E9%9D%A2%E6%A0%87%E9%A2%98.user.js', 'abc123', script.newest_saved_script_version.rewritten_code)
    user = User.find(1)
    push_webhook_request(user, path: 'TamperMonkey/BIT-%E8%A1%A5%E8%B6%B3%E9%A1%B5%E9%9D%A2%E6%A0%87%E9%A2%98.user.js')
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => ['https://greasyfork.org/en/scripts/1-a-test'], 'updated_failed' => [] }, response.parsed_body)
  end

  def test_webhook_push_non_ascii_filename_with_non_encoded_webhook
    script = scripts(:one)
    script.update!(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/TamperMonkey/BIT-%E8%A1%A5%E8%B6%B3%E9%A1%B5%E9%9D%A2%E6%A0%87%E9%A2%98.user.js')
    Git.expects(:get_contents).with('https://github.com/JasonBarnabe/webhooktest.git', { 'TamperMonkey/BIT-补足页面标题.user.js' => '7e1817e12430e179c0103c658018168f081336af' }).yields('TamperMonkey/BIT-补足页面标题.user.js', 'abc123', script.newest_saved_script_version.rewritten_code)
    user = User.find(1)
    push_webhook_request(user, path: 'TamperMonkey/BIT-补足页面标题.user.js')
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => ['https://greasyfork.org/en/scripts/1-a-test'], 'updated_failed' => [] }, response.parsed_body)
  end

  def test_webhook_push_github_refs_heads_format_sync_identifier
    script = Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js')
    script.update!(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/refs/heads/master/test.user.js')
    Git.expects(:get_contents).with('https://github.com/JasonBarnabe/webhooktest.git', { 'test.user.js' => '7e1817e12430e179c0103c658018168f081336af' }).yields('test.user.js', 'abc123', script.newest_saved_script_version.rewritten_code)
    user = User.find(1)
    push_webhook_request(user)
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => ['https://greasyfork.org/en/scripts/18-mb-funkey-illustrated-records-15'], 'updated_failed' => [] }, response.parsed_body)
  end

  def test_webhook_push_github_user_content_refs_heads_format_sync_identifier
    script = Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js')
    script.update!(sync_identifier: 'https://raw.githubusercontent.com/JasonBarnabe/webhooktest/refs/heads/master/test.user.js')
    Git.expects(:get_contents).with('https://github.com/JasonBarnabe/webhooktest.git', { 'test.user.js' => '7e1817e12430e179c0103c658018168f081336af' }).yields('test.user.js', 'abc123', script.newest_saved_script_version.rewritten_code)
    user = User.find(1)
    push_webhook_request(user)
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => ['https://greasyfork.org/en/scripts/18-mb-funkey-illustrated-records-15'], 'updated_failed' => [] }, response.parsed_body)
  end

  def test_webhook_release
    script = Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js')
    Git.expects(:get_contents).with('https://github.com/JasonBarnabe/webhooktest.git', { 'test.user.js' => 'v0.0.1' }).yields('test.user.js', 'abc123', script.newest_saved_script_version.rewritten_code)
    user = User.find(1)
    release_webhook_request(user)
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => ['https://greasyfork.org/en/scripts/18-mb-funkey-illustrated-records-15'], 'updated_failed' => [] }, response.parsed_body)
  end

  def test_webhook_release_with_raw_subdomain
    script = Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js')
    script.update!(sync_identifier: 'https://raw.githubusercontent.com/JasonBarnabe/webhooktest/master/test.user.js')
    Git.expects(:get_contents).with('https://github.com/JasonBarnabe/webhooktest.git', { 'test.user.js' => 'v0.0.1' }).yields('test.user.js', 'abc123', script.newest_saved_script_version.rewritten_code)
    user = User.find(1)
    release_webhook_request(user)
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => ['https://greasyfork.org/en/scripts/18-mb-funkey-illustrated-records-15'], 'updated_failed' => [] }, response.parsed_body)
  end

  def test_webhook_release_with_download_url
    script = Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js')
    script.update!(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/releases/latest/download/test.user.js')
    Git.expects(:get_contents).with('https://github.com/JasonBarnabe/webhooktest.git', { 'test.user.js' => 'v0.0.1' }).yields('test.user.js', 'abc123', script.newest_saved_script_version.rewritten_code)
    user = User.find(1)
    release_webhook_request(user)
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => ['https://greasyfork.org/en/scripts/18-mb-funkey-illustrated-records-15'], 'updated_failed' => [] }, response.parsed_body)
  end

  def test_webhook_release_no_match
    script = Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js')
    script.update!(sync_identifier: 'https://raw.githubusercontent.com/something/else/master/test.user.js')
    user = User.find(1)
    release_webhook_request(user)
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => [], 'updated_failed' => [], 'message' => 'No scripts found for this release.' }, response.parsed_body)
  end

  def test_webhook_release_file_not_in_git
    body = <<~JSON
      {
        "action": "published",
        "release": {
          "url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/releases/130333374",
          "assets_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/releases/130333374/assets",
          "upload_url": "https://uploads.github.com/repos/a1mersnow/aliyundrive-rename/releases/130333374/assets{?name,label}",
          "html_url": "https://github.com/a1mersnow/aliyundrive-rename/releases/tag/0.2.5",
          "id": 130333374,
          "author": {
            "login": "github-actions[bot]",
            "id": 41898282,
            "node_id": "MDM6Qm90NDE4OTgyODI=",
            "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
            "gravatar_id": "",
            "url": "https://api.github.com/users/github-actions%5Bbot%5D",
            "html_url": "https://github.com/apps/github-actions",
            "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
            "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
            "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
            "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
            "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
            "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
            "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
            "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
            "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
            "type": "Bot",
            "site_admin": false
          },
          "node_id": "RE_kwDOKqzSoc4HxLq-",
          "tag_name": "0.2.5",
          "target_commitish": "main",
          "name": "0.2.5",
          "draft": false,
          "prerelease": false,
          "created_at": "2023-11-20T11:54:49Z",
          "published_at": "2023-11-20T11:55:35Z",
          "assets": [

          ],
          "tarball_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/tarball/0.2.5",
          "zipball_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/zipball/0.2.5",
          "body": ""
        },
        "repository": {
          "id": 715969185,
          "node_id": "R_kgDOKqzSoQ",
          "name": "aliyundrive-rename",
          "full_name": "a1mersnow/aliyundrive-rename",
          "private": false,
          "owner": {
            "login": "a1mersnow",
            "id": 13799160,
            "node_id": "MDQ6VXNlcjEzNzk5MTYw",
            "avatar_url": "https://avatars.githubusercontent.com/u/13799160?v=4",
            "gravatar_id": "",
            "url": "https://api.github.com/users/a1mersnow",
            "html_url": "https://github.com/a1mersnow",
            "followers_url": "https://api.github.com/users/a1mersnow/followers",
            "following_url": "https://api.github.com/users/a1mersnow/following{/other_user}",
            "gists_url": "https://api.github.com/users/a1mersnow/gists{/gist_id}",
            "starred_url": "https://api.github.com/users/a1mersnow/starred{/owner}{/repo}",
            "subscriptions_url": "https://api.github.com/users/a1mersnow/subscriptions",
            "organizations_url": "https://api.github.com/users/a1mersnow/orgs",
            "repos_url": "https://api.github.com/users/a1mersnow/repos",
            "events_url": "https://api.github.com/users/a1mersnow/events{/privacy}",
            "received_events_url": "https://api.github.com/users/a1mersnow/received_events",
            "type": "User",
            "site_admin": false
          },
          "html_url": "https://github.com/a1mersnow/aliyundrive-rename",
          "description": "Aliyun Drive batch rename Tampermonkey script",
          "fork": false,
          "url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename",
          "forks_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/forks",
          "keys_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/keys{/key_id}",
          "collaborators_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/collaborators{/collaborator}",
          "teams_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/teams",
          "hooks_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/hooks",
          "issue_events_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/issues/events{/number}",
          "events_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/events",
          "assignees_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/assignees{/user}",
          "branches_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/branches{/branch}",
          "tags_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/tags",
          "blobs_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/git/blobs{/sha}",
          "git_tags_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/git/tags{/sha}",
          "git_refs_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/git/refs{/sha}",
          "trees_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/git/trees{/sha}",
          "statuses_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/statuses/{sha}",
          "languages_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/languages",
          "stargazers_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/stargazers",
          "contributors_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/contributors",
          "subscribers_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/subscribers",
          "subscription_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/subscription",
          "commits_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/commits{/sha}",
          "git_commits_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/git/commits{/sha}",
          "comments_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/comments{/number}",
          "issue_comment_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/issues/comments{/number}",
          "contents_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/contents/{+path}",
          "compare_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/compare/{base}...{head}",
          "merges_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/merges",
          "archive_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/{archive_format}{/ref}",
          "downloads_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/downloads",
          "issues_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/issues{/number}",
          "pulls_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/pulls{/number}",
          "milestones_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/milestones{/number}",
          "notifications_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/notifications{?since,all,participating}",
          "labels_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/labels{/name}",
          "releases_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/releases{/id}",
          "deployments_url": "https://api.github.com/repos/a1mersnow/aliyundrive-rename/deployments",
          "created_at": "2023-11-08T07:50:03Z",
          "updated_at": "2023-11-19T02:18:27Z",
          "pushed_at": "2023-11-20T11:55:09Z",
          "git_url": "git://github.com/a1mersnow/aliyundrive-rename.git",
          "ssh_url": "git@github.com:a1mersnow/aliyundrive-rename.git",
          "clone_url": "https://github.com/a1mersnow/aliyundrive-rename.git",
          "svn_url": "https://github.com/a1mersnow/aliyundrive-rename",
          "homepage": null,
          "size": 1446,
          "stargazers_count": 1,
          "watchers_count": 1,
          "language": "TypeScript",
          "has_issues": true,
          "has_projects": true,
          "has_downloads": true,
          "has_wiki": true,
          "has_pages": false,
          "has_discussions": false,
          "forks_count": 0,
          "mirror_url": null,
          "archived": false,
          "disabled": false,
          "open_issues_count": 0,
          "license": {
            "key": "mit",
            "name": "MIT License",
            "spdx_id": "MIT",
            "url": "https://api.github.com/licenses/mit",
            "node_id": "MDc6TGljZW5zZTEz"
          },
          "allow_forking": true,
          "is_template": false,
          "web_commit_signoff_required": false,
          "topics": [

          ],
          "visibility": "public",
          "forks": 0,
          "open_issues": 0,
          "watchers": 1,
          "default_branch": "main"
        },
        "sender": {
          "login": "github-actions[bot]",
          "id": 41898282,
          "node_id": "MDM6Qm90NDE4OTgyODI=",
          "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
          "gravatar_id": "",
          "url": "https://api.github.com/users/github-actions%5Bbot%5D",
          "html_url": "https://github.com/apps/github-actions",
          "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
          "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
          "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
          "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
          "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
          "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
          "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
          "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
          "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
          "type": "Bot",
          "site_admin": false
        }
      }
    JSON

    user = User.find(1)
    Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js').update!(sync_identifier: 'https://github.com/a1mersnow/aliyundrive-rename/releases/latest/download/aliyundrive-rename.user.js')
    Git.expects(:get_contents).with('https://github.com/a1mersnow/aliyundrive-rename.git', { 'aliyundrive-rename.user.js' => '0.2.5' }).raises(Git::Exception.new("fatal: path 'aliyundrive-rename.user.js' does not exist in '0.2.5'"))

    signature = OpenSSL::HMAC.hexdigest(UsersController::HMAC_DIGEST, user.webhook_secret, body)
    post user_webhook_url(user_id: user.id),
         headers: { 'Host' => 'greasyfork.org', 'Accept' => '*/*', 'User-Agent' => 'GitHub-Hookshot/8e03811', 'X-GitHub-Event' => 'release', 'X-GitHub-Delivery' => '2fdd0ba2-df8a-11e8-9fba-09ae25713944', 'content-type' => 'application/json', 'X-Hub-Signature' => "sha1=#{signature}", 'Content-Length' => body.bytesize, 'X-Forwarded-Proto' => 'https', 'X-Forwarded-For' => '192.30.252.44' },
         params: body
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => [], 'updated_failed' => ['http://localhost/scripts/18-mystring'], 'message' => "Could not pull contents from git: fatal: path 'aliyundrive-rename.user.js' does not exist in '0.2.5'" }, response.parsed_body)
  end

  def test_webhook_validation_error
    Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js')
    Git.expects(:get_contents).with('https://github.com/JasonBarnabe/webhooktest.git', { 'test.user.js' => '7e1817e12430e179c0103c658018168f081336af' }).yields('test.user.js', 'abc123', 'this is not valid js')
    user = User.find(1)
    push_webhook_request(user)
    assert_equal '200', response.code
    assert_equal({
                   'updated_scripts' => [],
                   'updated_failed' => ['https://greasyfork.org/en/scripts/18'],
                   'message' => 'https://greasyfork.org/en/scripts/18: Script versions is invalid, Default name is required - specify one with @name, Description is required - specify one with @description, Code contains errors: Uncaught SyntaxError: Unexpected identifier \'is\' at <eval>:2:5, Rewritten script code must exist, Code is invalid, Code must include at least one @match or @include key',
                 }, response.parsed_body)
  end
end
