require 'test_helper'
require 'git'

class BitbucketWebhookTest < ActionDispatch::IntegrationTest
  CHANGE_BODY = <<~'JSON'.freeze
    {
      "push": {
        "changes": [
          {
            "forced": false,
            "old": {
              "target": {
                "hash": "245bca724c148101632ace756f63095b8ba022e0",
                "links": {
                  "self": {
                    "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/commit/245bca724c148101632ace756f63095b8ba022e0"
                  },
                  "html": {
                    "href": "https://bitbucket.org/JasonBarnabe/webhookstest/commits/245bca724c148101632ace756f63095b8ba022e0"
                  }
                },
                "author": {
                  "raw": "Jason Barnabe <jason.barnabe@gmail.com>",
                  "type": "author",
                  "user": {
                    "username": "JasonBarnabe",
                    "display_name": "Jason Barnabe",
                    "account_id": "557058:5dabf523-623d-408d-b7a9-63c1b94205bc",
                    "links": {
                      "self": {
                        "href": "https://api.bitbucket.org/2.0/users/JasonBarnabe"
                      },
                      "html": {
                        "href": "https://bitbucket.org/JasonBarnabe/"
                      },
                      "avatar": {
                        "href": "https://bitbucket.org/account/JasonBarnabe/avatar/"
                      }
                    },
                    "type": "user",
                    "nickname": "JasonBarnabe",
                    "uuid": "{cc821ce6-0c1e-400e-b5fe-ad4ef350854f}"
                  }
                },
                "summary": {
                  "raw": "Initial commit\n",
                  "markup": "markdown",
                  "html": "<p>Initial commit</p>",
                  "type": "rendered"
                },
                "parents": [],
                "date": "2018-11-10T23:42:17+00:00",
                "message": "Initial commit\n",
                "type": "commit"
              },
              "links": {
                "commits": {
                  "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/commits/master"
                },
                "self": {
                  "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/refs/branches/master"
                },
                "html": {
                  "href": "https://bitbucket.org/JasonBarnabe/webhookstest/branch/master"
                }
              },
              "default_merge_strategy": "merge_commit",
              "merge_strategies": [
                "merge_commit",
                "squash",
                "fast_forward"
              ],
              "type": "branch",
              "name": "master"
            },
            "links": {
              "commits": {
                "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/commits?include=12245dbfb00de399a3108828b5aa2dc8bdbc4107&exclude=245bca724c148101632ace756f63095b8ba022e0"
              },
              "html": {
                "href": "https://bitbucket.org/JasonBarnabe/webhookstest/branches/compare/12245dbfb00de399a3108828b5aa2dc8bdbc4107..245bca724c148101632ace756f63095b8ba022e0"
              },
              "diff": {
                "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/diff/12245dbfb00de399a3108828b5aa2dc8bdbc4107..245bca724c148101632ace756f63095b8ba022e0"
              }
            },
            "truncated": false,
            "commits": [
              {
                "hash": "12245dbfb00de399a3108828b5aa2dc8bdbc4107",
                "links": {
                  "self": {
                    "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/commit/12245dbfb00de399a3108828b5aa2dc8bdbc4107"
                  },
                  "comments": {
                    "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/commit/12245dbfb00de399a3108828b5aa2dc8bdbc4107/comments"
                  },
                  "patch": {
                    "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/patch/12245dbfb00de399a3108828b5aa2dc8bdbc4107"
                  },
                  "html": {
                    "href": "https://bitbucket.org/JasonBarnabe/webhookstest/commits/12245dbfb00de399a3108828b5aa2dc8bdbc4107"
                  },
                  "diff": {
                    "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/diff/12245dbfb00de399a3108828b5aa2dc8bdbc4107"
                  },
                  "approve": {
                    "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/commit/12245dbfb00de399a3108828b5aa2dc8bdbc4107/approve"
                  },
                  "statuses": {
                    "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/commit/12245dbfb00de399a3108828b5aa2dc8bdbc4107/statuses"
                  }
                },
                "author": {
                  "raw": "Jason Barnabe <jason.barnabe@gmail.com>",
                  "type": "author",
                  "user": {
                    "username": "JasonBarnabe",
                    "display_name": "Jason Barnabe",
                    "account_id": "557058:5dabf523-623d-408d-b7a9-63c1b94205bc",
                    "links": {
                      "self": {
                        "href": "https://api.bitbucket.org/2.0/users/JasonBarnabe"
                      },
                      "html": {
                        "href": "https://bitbucket.org/JasonBarnabe/"
                      },
                      "avatar": {
                        "href": "https://bitbucket.org/account/JasonBarnabe/avatar/"
                      }
                    },
                    "type": "user",
                    "nickname": "JasonBarnabe",
                    "uuid": "{cc821ce6-0c1e-400e-b5fe-ad4ef350854f}"
                  }
                },
                "summary": {
                  "raw": "Test change\n",
                  "markup": "markdown",
                  "html": "<p>Test change</p>",
                  "type": "rendered"
                },
                "parents": [
                  {
                    "type": "commit",
                    "hash": "245bca724c148101632ace756f63095b8ba022e0",
                    "links": {
                      "self": {
                        "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/commit/245bca724c148101632ace756f63095b8ba022e0"
                      },
                      "html": {
                        "href": "https://bitbucket.org/JasonBarnabe/webhookstest/commits/245bca724c148101632ace756f63095b8ba022e0"
                      }
                    }
                  }
                ],
                "date": "2018-11-11T02:11:41+00:00",
                "message": "Test change\n",
                "type": "commit"
              }
            ],
            "created": false,
            "closed": false,
            "new": {
              "target": {
                "hash": "12245dbfb00de399a3108828b5aa2dc8bdbc4107",
                "links": {
                  "self": {
                    "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/commit/12245dbfb00de399a3108828b5aa2dc8bdbc4107"
                  },
                  "html": {
                    "href": "https://bitbucket.org/JasonBarnabe/webhookstest/commits/12245dbfb00de399a3108828b5aa2dc8bdbc4107"
                  }
                },
                "author": {
                  "raw": "Jason Barnabe <jason.barnabe@gmail.com>",
                  "type": "author",
                  "user": {
                    "username": "JasonBarnabe",
                    "display_name": "Jason Barnabe",
                    "account_id": "557058:5dabf523-623d-408d-b7a9-63c1b94205bc",
                    "links": {
                      "self": {
                        "href": "https://api.bitbucket.org/2.0/users/JasonBarnabe"
                      },
                      "html": {
                        "href": "https://bitbucket.org/JasonBarnabe/"
                      },
                      "avatar": {
                        "href": "https://bitbucket.org/account/JasonBarnabe/avatar/"
                      }
                    },
                    "type": "user",
                    "nickname": "JasonBarnabe",
                    "uuid": "{cc821ce6-0c1e-400e-b5fe-ad4ef350854f}"
                  }
                },
                "summary": {
                  "raw": "Test change\n",
                  "markup": "markdown",
                  "html": "<p>Test change</p>",
                  "type": "rendered"
                },
                "parents": [
                  {
                    "type": "commit",
                    "hash": "245bca724c148101632ace756f63095b8ba022e0",
                    "links": {
                      "self": {
                        "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/commit/245bca724c148101632ace756f63095b8ba022e0"
                      },
                      "html": {
                        "href": "https://bitbucket.org/JasonBarnabe/webhookstest/commits/245bca724c148101632ace756f63095b8ba022e0"
                      }
                    }
                  }
                ],
                "date": "2018-11-11T02:11:41+00:00",
                "message": "Test change\n",
                "type": "commit"
              },
              "links": {
                "commits": {
                  "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/commits/master"
                },
                "self": {
                  "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest/refs/branches/master"
                },
                "html": {
                  "href": "https://bitbucket.org/JasonBarnabe/webhookstest/branch/master"
                }
              },
              "default_merge_strategy": "merge_commit",
              "merge_strategies": [
                "merge_commit",
                "squash",
                "fast_forward"
              ],
              "type": "branch",
              "name": "master"
            }
          }
        ]
      },
      "repository": {
        "scm": "git",
        "website": "",
        "name": "webhookstest",
        "links": {
          "self": {
            "href": "https://api.bitbucket.org/2.0/repositories/JasonBarnabe/webhookstest"
          },
          "html": {
            "href": "https://bitbucket.org/JasonBarnabe/webhookstest"
          },
          "avatar": {
            "href": "https://bytebucket.org/ravatar/%7B97dde1b5-51fb-4f58-936d-f82d64d4a59b%7D?ts=default"
          }
        },
        "full_name": "JasonBarnabe/webhookstest",
        "owner": {
          "username": "JasonBarnabe",
          "display_name": "Jason Barnabe",
          "account_id": "557058:5dabf523-623d-408d-b7a9-63c1b94205bc",
          "links": {
            "self": {
              "href": "https://api.bitbucket.org/2.0/users/JasonBarnabe"
            },
            "html": {
              "href": "https://bitbucket.org/JasonBarnabe/"
            },
            "avatar": {
              "href": "https://bitbucket.org/account/JasonBarnabe/avatar/"
            }
          },
          "type": "user",
          "nickname": "JasonBarnabe",
          "uuid": "{cc821ce6-0c1e-400e-b5fe-ad4ef350854f}"
        },
        "type": "repository",
        "is_private": false,
        "uuid": "{97dde1b5-51fb-4f58-936d-f82d64d4a59b}"
      },
      "actor": {
        "username": "JasonBarnabe",
        "display_name": "Jason Barnabe",
        "account_id": "557058:5dabf523-623d-408d-b7a9-63c1b94205bc",
        "links": {
          "self": {
            "href": "https://api.bitbucket.org/2.0/users/JasonBarnabe"
          },
          "html": {
            "href": "https://bitbucket.org/JasonBarnabe/"
          },
          "avatar": {
            "href": "https://bitbucket.org/account/JasonBarnabe/avatar/"
          }
        },
        "type": "user",
        "nickname": "JasonBarnabe",
        "uuid": "{cc821ce6-0c1e-400e-b5fe-ad4ef350854f}"
      }
    }
  JSON

  def webhook_request(user, secret: nil)
    secret ||= user.webhook_secret
    post user_webhook_url(user_id: user.id, secret: secret),
         headers: { 'Host' => 'greasyfork.org', 'X-Forwarded-Proto' => 'https', 'X-Request-UUID' => 'cbb57380-2da5-4efa-9a69-fa61182bbccb', 'X-Event-Key' => 'repo:push', 'User-Agent' => 'Bitbucket-Webhooks/2.0', 'X-Attempt-Number' => '1', 'X-Hook-UUID' => '61bb6549-54df-4f62-81fe-350a0335d847', 'Content-Type' => 'application/json' },
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
    Git.expects(:get_files_changed).yields('12245dbfb00de399a3108828b5aa2dc8bdbc4107', ['test.user.js'])
    webhook_request(user)
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => [], 'updated_failed' => [] }, JSON.parse(response.body))
  end

  def test_webhook_change
    script = Script.find_by(sync_identifier: 'https://github.com/JasonBarnabe/webhooktest/raw/master/test.user.js')
    script.update!(sync_identifier: 'https://bitbucket.org/JasonBarnabe/webhookstest/raw/master/test.user.js')
    Git.expects(:get_contents).yields('test.user.js', '12245dbfb00de399a3108828b5aa2dc8bdbc4107', script.newest_saved_script_version.rewritten_code)
    Git.expects(:get_files_changed).yields('12245dbfb00de399a3108828b5aa2dc8bdbc4107', ['test.user.js'])
    user = User.find(1)
    webhook_request(user)
    assert_equal '200', response.code
    assert_equal({ 'updated_scripts' => ['https://greasyfork.org/en/scripts/18-mb-funkey-illustrated-records-15'], 'updated_failed' => [] }, JSON.parse(response.body))
  end
end
