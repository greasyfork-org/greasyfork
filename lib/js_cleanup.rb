require 'open3'

class JsCleanup
  def self.cleanup(js)
    pretty_js = nil
    stderr_msg = nil
    exit_status = nil

    Open3.popen3('yarn -s terser --format comments=false | yarn -s prettier --stdin-filepath script.js') do |stdin, stdout, stderr, wait_thr|
      stdin.print(js)
      stdin.close
      stderr_msg = stderr.read
      pretty_js = stdout.read
      exit_status = wait_thr.value
    end

    raise UncleanableException, stderr_msg if exit_status != 0

    pretty_js
  end

  class UncleanableException < StandardError; end
end
