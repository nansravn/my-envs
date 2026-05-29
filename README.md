# my-envs

Personal environment configuration, one folder per environment. Each folder is
self-contained: the config files plus scripts to **bootstrap** a fresh machine
and to **sync** local changes back into the repo.

## Environments

| Folder | Description |
| ------ | ----------- |
| [`windows-wsl/`](./windows-wsl) | Windows laptop, Ubuntu (WSL2) + Windows Terminal. zsh + Starship + modern CLI/Python kit. |

## Conventions

- Each env folder holds a `dotfiles/` tree mirroring `$HOME`, a `bootstrap.sh`
  to set up a new machine, and a `sync.sh` to copy the current live config back
  into the repo.
- Config files are **copies** (not symlinks). After changing a dotfile locally,
  run that env's `sync.sh` and commit.

## Adding a new environment

```bash
cp -r windows-wsl <new-env-name>   # use as a template, then adapt
```
