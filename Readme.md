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

(assuming repository is located in `~/bin`, shell is ZSH)

in `~/.zshrc`:

```sh
eval "$(~/bin/bin init)"
```
