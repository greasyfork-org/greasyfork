require 'open3'

class JsCleanup
  def self.cleanup(js)
    stdout, stderr, status = Open3.capture3('yarn -s terser --format comments=false | yarn -s prettier --stdin-filepath script.js', stdin_data: js)
    raise UncleanableException, stderr unless status.success?

    stdout
  end

  class UncleanableException < StandardError; end
end
