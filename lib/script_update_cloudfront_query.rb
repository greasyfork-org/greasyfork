require 'aws-sdk-athena'

class ScriptUpdateCloudfrontQuery
  def self.run(time = 1.hour.ago)
    client = Aws::Athena::Client.new(
      access_key_id: Rails.application.secrets.aws[:access_key_id],
      secret_access_key: Rails.application.secrets.aws[:secret_access_key],
      region: Rails.application.secrets.aws[:region]
    )

    date_param = time.utc.strftime('%Y-%m-%d')
    time_param = time.utc.strftime('%H')
    Rails.logger.info("Running with date #{date_param} and time #{time_param}.")

    resp = client.start_query_execution({
                                          query_string: query, # required
                                          work_group: 'primary',
                                          execution_parameters: ["CAST('#{date_param}' AS DATE)", "#{time_param}:%"],
                                        })

    execution_id = resp.query_execution_id

    max_wait_time = 30.seconds
    start = Time.zone.now
    while start + max_wait_time > Time.zone.now
      resp = client.get_query_execution({
                                          query_execution_id: execution_id, # required
                                        })
      case resp.query_execution.status.state
      when 'SUCCEEDED'
        break
      when 'QUEUED', 'RUNNING'
        next
      else
        raise "Query resulted in #{resp.query_execution.status.state}: #{resp.query_execution.status.state_change_reason}"
      end
    end

    resp = client.get_query_results({
                                      query_execution_id: execution_id,
                                    })

    process_results(resp)

    while resp.next_token
      resp = client.get_query_results({
                                        query_execution_id: execution_id,
                                        next_token: resp.next_token,
                                      })
      process_results(resp)
    end
  end

  def self.process_results(resp)
    data = resp.result_set.rows
               .map { |row| row.data.map(&:var_char_value) }
               .reject { |ip, _script_id, _req_time| ip == 'c_ip' } # Ignore header
               .map { |ip, script_id, req_time| { ip:, script_id:, update_date: Time.find_zone('UTC').parse(req_time) } }

    Rails.logger.info("Importing #{data.count} rows.")
    DailyUpdateCheckCount.insert_all(data) if data.any?
  end

  def self.query
    <<~SQL.squish
      SELECT c_ip, regexp_extract(cs_uri_stem, '^/scripts/([0-9]+)[-./]', 1) AS script_id, MIN(CAST(date AS VARCHAR) || ' ' || time) AS req_datetime
      FROM cloudfront_logs
      WHERE cs_uri_stem LIKE '/scripts/%.meta.js'
      AND date = ?
      AND time LIKE ?
      AND sc_status IN (200, 304)
      AND cs_uri_query = '-'
      GROUP BY c_ip, regexp_extract(cs_uri_stem, '^/scripts/([0-9]+)[-./]', 1);
    SQL
  end
end
