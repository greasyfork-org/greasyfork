require 'open3'

class JsCleanup
  def self.cleanup(js)
    # Run in two separate commands rather than piping so we can catch if the first one fails.
    stdout, stderr, status = Open3.capture3('yarn -s terser --format comments=false', stdin_data: js)
    raise UncleanableException, stderr unless status.success?

    stdout, stderr, status = Open3.capture3('yarn -s prettier --stdin-filepath script.js', stdin_data: stdout)
    raise UncleanableException, stderr unless status.success?

    stdout
  end

  class UncleanableException < StandardError; end
end
