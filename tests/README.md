# Docker tests

Verifies that the setup scripts and the Neovim config in this repo work on a
clean Arch Linux, Ubuntu and Fedora system, using throw-away Docker containers.

```console
$ tests/run-docker-tests.sh              # all three distros
$ tests/run-docker-tests.sh arch         # one distro
$ tests/run-docker-tests.sh -d arch,ubuntu
$ tests/run-docker-tests.sh --quick      # fast: no package installs, no plugin sync
$ tests/run-docker-tests.sh --full       # also runs setup.sh end to end
$ tests/run-docker-tests.sh --shell arch # poke around inside the image
```

The repo is bind-mounted read only and copied to `~/.zprezto` inside the
container, so your working tree is tested as-is (uncommitted changes included)
and nothing on the host is touched. Logs land in `tests/.logs/<distro>.log`.

## What runs

| Mode | Checks |
| --- | --- |
| `--quick` | script syntax (`zsh -n` / `bash -n`), `setup-symlinks.sh`, zsh and bash startup |
| default | the above plus `scripts/install-dev-tools.sh` and the full Neovim config: lazy.nvim sync, every plugin module loading, colorscheme/lualine/bufferline actually applied, treesitter, keymaps, the Mason registry, a real `:MasonInstall` of lua-language-server / pyright / jdtls, and each of those attaching to a Lua, Python and Java buffer |
| `--full` | the above with `setup.sh` driven end to end instead of the individual scripts |

Everything the repo is supposed to install is deliberately absent from the
images — only a shell, git, curl and a compiler are baked in — so the install
scripts are exercised for real.

## Neovim version

The config needs Neovim >= 0.11. Ubuntu 24.04 ships 0.9.5, so by default
(`--nvim auto`) the suite falls back to the official Neovim release tarball
when the distro package is too old. Use `--nvim distro` to fail instead, or
`--nvim upstream` to always use the release tarball.

## Notes

* Tests run as root inside the container; that is what lets `chsh` and the
  package managers work unattended.
* `archlinux:base` is x86_64 only, so on Apple Silicon (and other arm64 hosts)
  the Arch image is built from `menci/archlinuxarm:base`.
* Warnings are informational and do not fail the run; failures do.
