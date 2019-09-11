require 'bundler/audit/database'
require 'bundler/audit/scanner'

class DependenciesTest < ActiveSupport::TestCase

  IGNORED_VULNERABILITIES = ['CVE-2015-9284']

  test 'for gem vulnerabilities' do
    Bundler::Audit::Database.update!(quiet: true)
    vulnerabilities = Bundler::Audit::Scanner.new.scan.to_a

    ignored_vulnerabilities, reported_vulnerabilities = vulnerabilities.partition{ |r| IGNORED_VULNERABILITIES.include?(r.advisory.id) }
    if ignored_vulnerabilities.any? && reported_vulnerabilities.none?
      skip "Ignored advisories: #{vulnerability_string(ignored_vulnerabilities)}"
    end
    
    assert_empty(reported_vulnerabilities, vulnerability_string(reported_vulnerabilities))
  end
  
  def vulnerability_string(vulnerabilities)
    vulnerabilities.map{|r| r.is_a?(Bundler::Audit::Scanner::UnpatchedGem) ? "#{r.gem}, #{r.advisory}" : r.to_s }.join('; ')
  end
end
