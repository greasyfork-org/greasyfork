require 'mini_racer'
require_relative '../lib/js_executor'

$stdout.sync = true
JsExecutor.extract_urls_in_process($stdin.read) { |url| puts JSON.generate(url) }
