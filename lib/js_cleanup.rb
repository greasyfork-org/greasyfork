require 'open3'

class JsCleanup
  def self.cleanup(js)
    Open3.popen2('yarn -s terser --format comments=false --mangle toplevel=true | yarn -s prettier --stdin-filepath script.js') do |stdin, stdout|
      stdin.print(js)
      stdin.close
      return stdout.read
    end
  end
end
