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
  tar(1)
  unzip(1)
  wget(1)
  which(1)

=end

class Bin < Thor
  BIN_DIR = File.expand_path('..', __FILE__)
  LIB_DIR = File.expand_path('lib', BIN_DIR)

  SBT_VERSION = '0.13.0'

  SBT_LAUNCH_URI =
    "http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch/#{SBT_VERSION}/sbt-launch.jar"

  # v3.2.13-1-x86_64
  ODESK_TEAM_URI =
    'https://docs.google.com/uc?export=download&id=0B1NdDtEdfiQpTkRrOFREdTdNcnc'

  # v2.03 (September 21, 2013)
  K2PDFOPT_URI =
    'https://docs.google.com/uc?export=download&id=0B1NdDtEdfiQpSDJjLThWRnZuRU0'

  DART_SDK_URI =
    'https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip'

  COPY_URI = 'https://copy.com/install/linux/Copy.tgz'

  SCRIPTS = {
    'git-wip' => 'https://raw.github.com/bartman/git-wip/master/git-wip',
    'hub' => 'http://hub.github.com/standalone',
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
    ensure_directory_exists LIB_DIR

    target = File.expand_path('sbt-launch.jar', LIB_DIR)
    FileUtils.rm_f target

    download_file SBT_LAUNCH_URI, target
  end

  desc 'odeskteam', 'install "oDesk Team" application (https://www.odesk.com/downloads)'
  def odeskteam
    ensure_directory_exists LIB_DIR

    dist_location =  File.expand_path('odeskteam-3.2.13-1-x86_64', LIB_DIR)

    in_temporary_directory do
      target = File.expand_path('odeskteam.zip', Dir.pwd)
      download_file ODESK_TEAM_URI, target
      FileUtils.rm_rf dist_location
      system 'unzip', target, '-d', LIB_DIR
    end
  end

  desc 'k2pdfopt', 'install k2pdfopt (http://www.willus.com/k2pdfopt/)'
  def k2pdfopt
    location_of('k2pdfopt').tap do |k2pdfopt|
      download_file K2PDFOPT_URI, k2pdfopt
      File.chmod 0744, k2pdfopt
    end
  end

  desc 'dart', 'install Dart SDK (http://www.dartlang.org/tools/sdk)'
  def dart
    ensure_directory_exists LIB_DIR

    dist_location = File.expand_path('dart-sdk', LIB_DIR)

    in_temporary_directory do
      target = File.expand_path('dart-sdk', Dir.pwd)
      download_file DART_SDK_URI, target
      FileUtils.rm_rf dist_location
      system 'unzip', target, '-d', LIB_DIR
    end
  end

  desc 'copy', 'install Copy{Agent,Console,Cmd} tools (http://copy.com)'
  def copy
    ensure_directory_exists LIB_DIR

    dist_location = File.expand_path('copy', LIB_DIR)

    in_temporary_directory do
      target = File.expand_path('copy', Dir.pwd)
      download_file COPY_URI, target
      FileUtils.rm_rf dist_location
      system 'tar', '--extract', '--gzip', '--file', target, '--directory', LIB_DIR
    end
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
      binary = location_of(name)
      FileUtils.rm_f binary
      FileUtils.cp name, binary
    end

    def symlink_executable(from, to)
      IO.popen ['which', from] do |io|
        source = io.read.chomp
        io.close

        if $CHILD_STATUS.success?
          target = location_of(to)
          FileUtils.ln_sf source, target
        else
          say "no #{from} executable found", :red
        end
      end
    end

    def location_of(executable)
      File.expand_path(executable.to_s, BIN_DIR)
    end

    def strip_binaries
      Dir[location_of('*')]
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
      system 'wget', String(uri), '-O', target
    end

    def in_github_repo(repo, &block)
      in_git_repo "https://github.com/#{repo}.git", &block
    end

    def in_git_repo(uri, &block)
      repo_dir =  uri[%r((?<=/)[^/]+(?=\.git\z))] || 'git_repo'

      in_temporary_directory do
        system 'git', 'clone', uri, repo_dir
        Dir.chdir repo_dir, &block
      end
    end

    def in_temporary_directory(&block)
      Dir.mktmpdir do |tmpdir|
        Dir.chdir tmpdir, &block
      end
    end

    def ensure_directory_exists(dir)
      Dir.mkdir dir unless File.directory?(dir)
    end
  end
end
