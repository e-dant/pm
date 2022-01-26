# pm

`pm` is a hackable package manager for things that aren't packages. Namely: 

- libraries
- configuration files
- build systems
- configurable binaries

## Rationale

`pm` is meant to be unobtrusive and simple. It is, ultimately, just a collection of scripts created for the purpose of organizing my own projects. It became obtrusive organizing, updating, and remembering how to build projects. This is a solution for that in the form of an organization and build utility; a front-end, of limited sorts, to packaged code.

There are five broad categories of code with which I have found `pm` useful:

1. `stores`: unorganized code; think of it as a bookmark which can be `gzip`ped
1. `sources`: raw source code which lacks an *installation* script but has a *build* script (or identifiable build system)
1. `builds`: the output of the corresponding `sources` sub-directory (or, otherwise, your own non-`pm` builds)
1. `configurations`: system configuration programs (such as font installers, apache configurations, and system migrations)
1. `distributions`: full packages which are accompanied by a `module.sh` (such as offline downloads of a .deb package or an emulator for a client's .apk programs).

I have found that code of all shapes and sizes fits roughly into one of those five categories. Feel free to use as many or as few as you wish. `pm` has built-in tools for handling, searching, and organizing each of them (with the exception of `stores`; nothing happens there).

of all shapes and sizes. I've found it helpful in making website migrations, operating system migrations, modular embedded systems installations, and offline package installations (when your primary package manager is not present, of course).

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


