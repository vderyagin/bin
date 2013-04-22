require 'open-uri'

class Update < Thor
  BIN_DIR = File.expand_path('..', __FILE__)

  SCRIPTS = {
    'git-wip' => 'https://raw.github.com/bartman/git-wip/master/git-wip',
    'hub' => 'http://defunkt.io/hub/standalone',
    'lein' => 'https://raw.github.com/technomancy/leiningen/stable/bin/lein',
  }

  desc 'all', 'update all scripts'
  def all
    SCRIPTS.each do |script, location|
      file = location_of(script)

      print "updating #{script}... "

      begin
        content = open(location).read
      rescue StandardError => err
        print "failed: #{err.message}\n"
      else
        print "done\n"
        File.write file, content
        File.chmod 0744, file
      end
    end
  end

  no_commands do
    def location_of(script_name)
      File.expand_path(script_name.to_s, BIN_DIR)
    end
  end
end
