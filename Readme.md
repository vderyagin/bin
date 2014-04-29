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

(assuming repository is located in `~/bin`)

### zsh ###

in `~/.zshrc`:

```sh
source "${HOME}/bin/init.zsh"
```

### bash ###

in `~/.bash_profile`:

```sh
source "${HOME}/bin/init.bash"
```
