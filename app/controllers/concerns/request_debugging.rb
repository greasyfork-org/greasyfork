module RequestDebugging
  extend ActiveSupport::Concern

  def log_headers
    Rails.root.join('log/debug_headers.txt').write(request.url + "\n" + DateTime.now.to_s + "\n" + request.headers.select { |key, _val| key.starts_with?('HTTP_') }.map { |key, val| "#{key}: #{val}" }.join("\n") + "\n\n", mode: 'a+')
  end
end
