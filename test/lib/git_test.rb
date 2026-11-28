require 'test_helper'
require 'git'
require 'open3'
require 'tmpdir'

class GitTest < ActiveSupport::TestCase
  test 'revision order follows commit ancestry' do
    Dir.mktmpdir('git-revision-order') do |directory|
      repository = File.join(directory, 'repository')
      git!('init', [repository])
      git!('config', ['user.email', 'test@example.com'], chdir: repository)
      git!('config', ['user.name', 'Test User'], chdir: repository)

      git!('commit', ['--allow-empty', '-m', 'A'], chdir: repository)
      revision_a = git!('rev-parse', ['HEAD'], chdir: repository).strip
      git!('commit', ['--allow-empty', '-m', 'B'], chdir: repository)
      revision_b = git!('rev-parse', ['HEAD'], chdir: repository).strip

      assert_equal :incoming_newer, Git.revision_order(repository, revision_a, revision_b)
      assert_equal :incoming_older, Git.revision_order(repository, revision_b, revision_a)
    end
  end

  test 'revision order treats a missing saved revision as replaceable but a missing incoming revision as an error' do
    Dir.mktmpdir('git-revision-order') do |directory|
      repository = File.join(directory, 'repository')
      git!('init', [repository])
      git!('config', ['user.email', 'test@example.com'], chdir: repository)
      git!('config', ['user.name', 'Test User'], chdir: repository)
      git!('commit', ['--allow-empty', '-m', 'A'], chdir: repository)
      revision_a = git!('rev-parse', ['HEAD'], chdir: repository).strip
      missing_revision = 'f' * 40

      assert_equal :current_missing, Git.revision_order(repository, missing_revision, revision_a)
      assert_raises(Git::Exception) { Git.revision_order(repository, revision_a, missing_revision) }
    end
  end

  private

  def git!(command, arguments = [], chdir: nil)
    options = {}
    options[:chdir] = chdir unless chdir.nil?
    output, error, status = Open3.capture3('git', command, *arguments, **options)
    raise error unless status.success?

    output
  end
end
