path=(
  "${HOME}/bin"
  "${HOME}/bin/lib/copy/x86_64"
  "${HOME}/bin/lib/dart-sdk/bin"
  "${HOME}/bin/lib/google-cloud-sdk/bin"
  "${HOME}/bin/lib/heroku-client/bin"
  "${HOME}/bin/lib/odeskteam-3.2.13-1-x86_64/usr/bin"
  $path
)

fpath=(
  "${HOME}/bin/lib/zsh-completions/src"
  $fpath
)

source "${HOME}/bin/lib/google-cloud-sdk/completion.zsh.inc"

declare -U path
declare -U fpath
