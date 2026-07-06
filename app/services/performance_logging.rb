class PerformanceLogging
  def self.log_timing(topic:, context:, data: nil)
    start = Time.current
    rv = yield
    duration = Time.current - start
    Rails.root.join("log/#{topic}.log").write("#{DateTime.now},#{context},#{duration},#{data}\n", mode: 'a+')
    rv
  end

  def self.log_elasticsearch(context, data: nil, &)
    log_timing(topic: 'elasticsearch', context:, data:, &)
  end
end
