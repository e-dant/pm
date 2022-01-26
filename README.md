# pm

`pm` is a hackable package manager for things that aren't packages. Namely: 

- libraries
- configuration files
- build systems
- configurable binaries

This is meant to be unobtrusive and simple. Install it anywhere, take a sledgehammer to it, use any build system, whatever. This is, ultimately, just a collection of scripts which I have been using and have found helpful in organizing my own projects of all shapes and sizes. I've found it helpful in making website migrations, operating system migrations, modular embedded systems installations, and offline package installations (when your primary package manager is not present, of course).

## Usage

```
pm(usage|help[raw|pretty[full|key]=>pretty])
pm(install|add(package(version=>latest)))
pm(query|info(module(version=>latest)))
pm(module(module,([help|usage]|[install|install]|describe|run)))
pm(methods[raw|pretty=>pretty])
pm(create(name,version)
pm(manifest|scan)
pm(list)
```

## Installation

Just add this line into your favorite shell's profile:
```
source <the directory you cloned pm into>/.internals/constitution.sh
```

Usually, the profile is one of these:

```
~/.zshrc
~/.bashrc
~/.profile
~/.bash_profile
~/.config/fish/config.fish
```

## Adding packages

Just run `pm create <your new package's name>` and add whatever you'd like into the resulting `module.sh`.


