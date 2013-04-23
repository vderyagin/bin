require 'fileutils'
require 'tmpdir'

class Build < Thor
  desc 'all', 'build all binary executables'
  def all
    invoke :emxkb
    invoke :skb
    invoke :dzen2
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
          FileUtils.mv 'skb', File.expand_path('../', __FILE__)
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
          FileUtils.mv 'dzen2', File.expand_path('../', __FILE__)
        end

        FileUtils.rm_r 'dzen'
      end
    end
  end
end
