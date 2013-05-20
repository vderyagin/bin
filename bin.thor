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
      content = url_content(location)
      replace_executable(file, content) if content
    end
  end

  desc 'sbt', 'get jar needed to run sbt'
  def sbt
    url = 'http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch//0.12.3/sbt-launch.jar'

    lib_dir = File.expand_path('lib', BIN_DIR)
    FileUtils.rm_f File.expand_path('sbt-launch.jar', lib_dir)
    Dir.mkdir lib_dir unless File.directory?(lib_dir)
    system 'wget', '--directory-prefix', 'lib', url
  end

  desc 'emxkb', 'build emxkb from source'
  def emxkb
    FileUtils.rm_f location_of('emxkb')
    system 'gcc', '-L/usr/X11R6/lib', '-lX11', '-o', 'emxkb', 'src/emxkb.c'
  end

  desc 'skb', 'download skb source and build it'
  def skb
    Dir.mktmpdir do |tmpdir|
      Dir.chdir tmpdir do
        system 'git', 'clone', 'https://github.com/polachok/skb.git'

        Dir.chdir 'skb' do
          system 'make', 'skb'
          place_binary 'skb'
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
          place_binary 'dzen2'
        end

        FileUtils.rm_r 'dzen'
      end
    end
  end

  desc 'hsmarkdown', 'make symlink pandoc -> hsmarkdown'
  def hsmarkdown
    symlink_executable 'pandoc', 'hsmarkdown'
  end

  desc 'unrar_free', 'make symlink unrar-gpl -> unrar-free'
  def unrar_free
    symlink_executable 'unrar-gpl', 'unrar-free'
  end

  no_commands do
    def url_content(url)
      content = open(url).read
    rescue StandardError => err
      puts "failed: #{err.message}"
    else
      puts 'done'
      content
    end

    def replace_executable(file, content)
      FileUtils.rm_f file
      File.write file, content
      File.chmod 0744, file
    end

    def place_binary(name)
      binary = File.expand_path(name, BIN_DIR)
      FileUtils.rm_f binary
      FileUtils.cp name, binary
    end

    def symlink_executable(from, to)
      IO.popen(['which', from]) do |io|
        source = io.read.chomp
        io.close

        if $CHILD_STATUS.success?
          target = File.expand_path(to, BIN_DIR)
          FileUtils.ln_sf source, target
        else
          warn "no #{from} executable found"
        end
      end
    end

    def location_of(script_name)
      File.expand_path(script_name.to_s, BIN_DIR)
    end
  end
end
