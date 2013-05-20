require 'English'
require 'fileutils'
require 'net/http'
require 'open-uri'
require 'tmpdir'
require 'uri'

=begin

Shells out to:

  file(1)
  gcc(1)
  git(1)
  make(1)
  strip(1)
  which(1)

=end

class Bin < Thor
  BIN_DIR = File.expand_path('..', __FILE__)

  SBT_VERSION = '0.12.3'

  SBT_LAUNCH_URI =
    'http://repo.typesafe.com/' +
    'typesafe/ivy-releases/org.scala-sbt/sbt-launch/' +
    SBT_VERSION +
    '/sbt-launch.jar'

  SCRIPTS = {
    'git-wip' => 'https://raw.github.com/bartman/git-wip/master/git-wip',
    'hub' => 'http://defunkt.io/hub/standalone',
    'lein' => 'https://raw.github.com/technomancy/leiningen/stable/bin/lein',
  }

  desc 'all', 'do everyting'
  def all
    invoke_all
    strip_binaries
  end

  desc 'scripts', 'update all scripts'
  def scripts
    SCRIPTS.each do |script, location|
      file = location_of(script)
      say "updating #{script}... "
      content = url_content(location)
      replace_executable(file, content) if content
    end
  end

  desc 'sbt', 'get jar needed to run sbt'
  def sbt
    lib_dir = File.expand_path('lib', BIN_DIR)
    Dir.mkdir lib_dir unless File.directory?(lib_dir)

    target = File.expand_path('sbt-launch.jar', lib_dir)
    FileUtils.rm_f target

    download_file SBT_LAUNCH_URI, target
  end

  desc 'emxkb', 'build emxkb from source'
  def emxkb
    FileUtils.rm_f location_of('emxkb')
    system 'gcc', '-L/usr/X11R6/lib', '-lX11', '-o', 'emxkb', 'src/emxkb.c'
  end

  desc 'skb', 'download skb source and build it'
  def skb
    in_github_repo 'polachok/skb' do
      system 'make', 'skb'
      place_binary 'skb'
    end
  end

  desc 'dzen2', 'download dzen2 source and build it'
  def dzen2
    in_github_repo 'robm/dzen' do
      system 'make'
      place_binary 'dzen2'
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
      say "failed: #{err.message}"
    else
      say 'done'
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
      IO.popen ['which', from] do |io|
        source = io.read.chomp
        io.close

        if $CHILD_STATUS.success?
          target = File.expand_path(to, BIN_DIR)
          FileUtils.ln_sf source, target
        else
          say "no #{from} executable found", :red
        end
      end
    end

    def location_of(script_name)
      File.expand_path(script_name.to_s, BIN_DIR)
    end

    def strip_binaries
      Dir[File.expand_path('*', BIN_DIR)]
        .select(&method(:unstripped_binary?))
        .each(&method(:strip))
    end

    def strip(file)
      say "stripping binary file #{file}"
      system 'strip', file
    end

    def unstripped_binary?(file)
      IO.popen(['file', file]).read[/, not stripped$/]
    end

    def download_file(uri, target)
      u = URI(uri)

      host = u.host
      path = u.path
      io = open(target, 'wb')

      Net::HTTP.start host do |http|
        stream_http http, path, io
      end
    end

    def stream_http(http, path, io)
      http.request_get path do |response|
        response.read_body do |segment|
          io.write segment
        end
      end
    ensure
      io.close
    end

    def in_github_repo(repo, &block)
      in_git_repo "https://github.com/#{repo}.git", &block
    end

    def in_git_repo(uri, &block)
      repo_dir =  uri[%r((?<=/)[^/]+(?=\.git\z))] || 'git_repo'

      in_temporary_directory do
        begin
          system 'git', 'clone', uri, repo_dir
          Dir.chdir repo_dir, &block
        ensure
          FileUtils.rm_rf repo_dir
        end
      end
    end

    def in_temporary_directory(&block)
      Dir.mktmpdir do |tmpdir|
        Dir.chdir tmpdir, &block
      end
    end
  end
end
