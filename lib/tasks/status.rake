require 'json'
require 'uri'
require 'net/http'

namespace :status do

  desc 'check delayed job backlog'
  task delayed_job: :environment do
    pending_count = Script.connection.select_value('SELECT COUNT(*) FROM delayed_jobs WHERE last_error IS NULL')
    if pending_count > 100
      ActionMailer::Base.mail(
        from: "noreply@greasyfork.org", 
        to: "jason.barnabe@gmail.com", 
        subject: "Delayed job pending count", 
        body: "There are #{pending_count} pending delayed jobs."
      ).deliver_now
    end
  end

end
