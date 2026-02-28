module HelpHelper
  def financial_credits
    [
      ['Dotcom-Monitor', 'https://www.dotcom-monitor.com/'],
      ['LoadView', 'https://www.loadview-testing.com/'],
      ['Web Hosting Buddy', 'https://webhostingbuddy.com/'],
      ['Find My Electric', 'https://www.findmyelectric.com/']
    ].map { |name, url| link_to(name, url) }.to_sentence.html_safe
  end

  def admin_email
    'jason.barnabe@gmail.com'
  end

  def admin_email_url
    "mailto:#{admin_email}"
  end
end