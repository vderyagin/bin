class Build < Thor
  desc 'emxkb', 'build emxkb from source'
  def emxkb
    system 'gcc', '-L/usr/X11R6/lib', '-lX11', '-o', 'emxkb', 'src/emxkb.c'
  end
end
