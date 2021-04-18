require 'bundler/audit/database'
require 'bundler/audit/scanner'
require 'fileutils'

class DependenciesTest < ActiveSupport::TestCase
  IGNORED_VULNERABILITIES = [].freeze

  test 'for gem vulnerabilities' do
    FileUtils.mkdir_p(Bundler::Audit::Database::USER_PATH)

    scanner = Bundler::Audit::Scanner.new
    scanner.database.update!(quiet: true)
    vulnerabilities = scanner.scan.to_a

    ignored_vulnerabilities, reported_vulnerabilities = vulnerabilities.partition { |r| r.respond_to?(:advisory) && IGNORED_VULNERABILITIES.include?(r.advisory.id) }
    skip "Ignored advisories: #{vulnerability_string(ignored_vulnerabilities)}" if ignored_vulnerabilities.any? && reported_vulnerabilities.none?

    assert_empty(reported_vulnerabilities, vulnerability_string(reported_vulnerabilities))
  end

  def vulnerability_string(vulnerabilities)
    vulnerabilities.map { |r| r.is_a?(Bundler::Audit::Results::UnpatchedGem) ? "#{r.gem}, #{r.advisory}" : r.to_s }.join('; ')
  end
end
