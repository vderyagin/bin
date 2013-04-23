require 'English'
require 'fileutils'
require 'open-uri'
require 'tmpdir'

class Bin < Thor
  BIN_DIR = File.expand_path('..', __FILE__)

  SCRIPTS = {
    'git-wip' => 'https://raw.github.com/bartman/git-wip/master/git-wip',
    'hub' => 'http://defunkt.io/hub/standalone',
    'lein' => 'https://raw.github.com/technomancy/leiningen/stable/bin/lein',
  }

  desc 'all', 'do everyting'
  alias_method :all, :invoke_all

  desc 'scripts', 'update all scripts'
  def scripts
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

  desc 'skb', 'get jar needed to run sbt'
  def sbt
    url = 'http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch//0.12.3/sbt-launch.jar'

    lib_dir = File.expand_path('lib', BIN_DIR)
    FileUtils.rm_f File.expand_path('sbt-launch.jar', lib_dir)
    Dir.mkdir lib_dir unless File.directory?(lib_dir)
    system 'wget', '--directory-prefix', 'lib', url
  end

  desc 'emxkb', 'build emxkb from source'
  def emxkb
    system 'gcc', '-L/usr/X11R6/lib', '-lX11', '-o', 'emxkb', 'src/emxkb.c'
  end

  desc 'skb', 'download skb source and build it'
  def skb
    Dir.mktmpdir do |tmpdir|
      Dir.chdir tmpdir do
        system 'git', 'clone', 'https://github.com/polachok/skb.git'

        Dir.chdir 'skb' do
          system 'make', 'skb'
          binary = File.expand_path('skb', BIN_DIR)

          FileUtils.rm_f binary
          FileUtils.cp 'skb', binary
        end

        FileUtils.rm_r 'skb'
      end
    end
  end

  desc 'dzen2', 'download dzen2 source and build it'
  def dzen2
    Dir.mktmpdir do |tmpdir|
      Dir.chdir tmpdir do
        system 'git', 'clone', 'https://github.com/robm/dzen.git'

        Dir.chdir 'dzen' do
          system 'make'
          binary = File.expand_path('dzen2', BIN_DIR)

          FileUtils.rm_f binary
          FileUtils.cp 'dzen2', binary
        end

        FileUtils.rm_r 'dzen'
      end
    end
  end

  desc 'unrar_free', 'make symlink unrar-gpl -> unrar-free'
  def unrar_free
    unrar_gpl = `which unrar-gpl`.chomp
    warn 'no unrar-gpl executable found' unless $CHILD_STATUS.success?
    FileUtils.ln_sf unrar_gpl, File.expand_path('unrar-free', BIN_DIR)
  end

  no_commands do
    def location_of(script_name)
      File.expand_path(script_name.to_s, BIN_DIR)
    end
  end
end
