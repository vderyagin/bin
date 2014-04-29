## Installation of dependencies ##

### system ###

(assuming Gentoo GNU/Linux with portage)

```sh
emerge --noreplace file gcc git go make tar unzip wget which
```

### gems ###

```sh
bundle
```

## Set up environment variables ##

(in `~/.zshrc`, assuming repository is located in `~/bin`)

```sh
source "${HOME}/bin/init.zsh"
```
