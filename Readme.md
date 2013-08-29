## Install dependencies ##

(assuming Gentoo GNU/Linux with portage)

```sh
emerge --noreplace file gcc git make tar unzip wget which
```

## Set up PATH ##

(assuming zsh, repository is located ad `${HOME}/bin`)

```sh
path=(
  "${HOME}/bin"
  "${HOME}/bin/lib/dart-sdk/bin"
  "${HOME}/bin/lib/odeskteam-3.2.13-1-x86_64/usr/bin"
  "${HOME}/bin/lib/copy/x86_64"
  $path
)
```
