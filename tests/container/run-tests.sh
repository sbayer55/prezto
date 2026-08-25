#!/usr/bin/env bash
#
# In-container test suite for the zprezto setup scripts and neovim config.
#
# This is not meant to be run directly on a workstation: it installs packages,
# rewrites ~/.zshrc and friends, and generally treats $HOME as disposable.
# tests/run-docker-tests.sh runs it inside a throw-away container.
#
# Environment:
#   DISTRO       arch|ubuntu|fedora    label used in output
#   MODE         quick|default|full    how much to exercise (default: default)
#   NVIM_SOURCE  auto|distro|upstream  where neovim comes from (default: auto)
#   REPO_SRC     path to the repo checkout mounted read-only (default: /repo)

set -uo pipefail

DISTRO="${DISTRO:-unknown}"
MODE="${MODE:-default}"
NVIM_SOURCE="${NVIM_SOURCE:-auto}"
REPO_SRC="${REPO_SRC:-/repo}"

# The setup scripts hard-code ~/.zprezto, so the checkout has to live there.
ZPREZTO_HOME="${HOME}/.zprezto"

# Minimum neovim the .config/nvim config needs (vim.hl.on_yank, treesitter
# foldexpr, vim.lsp.config-era APIs).
readonly NVIM_MIN_MAJOR=0
readonly NVIM_MIN_MINOR=11

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

PASSED=0
FAILED=0
WARNED=0
SKIPPED=0
FAILED_NAMES=()
WARNED_NAMES=()

log()  { echo -e "${BLUE}==>${NC} $*"; }
pass() { PASSED=$((PASSED + 1)); echo -e "  ${GREEN}PASS${NC} $*"; }
fail() { FAILED=$((FAILED + 1)); FAILED_NAMES+=("$1"); echo -e "  ${RED}FAIL${NC} $*"; }
warn() { WARNED=$((WARNED + 1)); WARNED_NAMES+=("$1"); echo -e "  ${YELLOW}WARN${NC} $*"; }
skip() { SKIPPED=$((SKIPPED + 1)); echo -e "  ${CYAN}SKIP${NC} $*"; }

# Print a command's captured output indented, so failures are debuggable.
show() {
    local file="$1" limit="${2:-40}"
    [[ -s "${file}" ]] || return 0
    sed -e "s/^/      | /" -e "${limit}q" "${file}"
    if (( $(wc -l < "${file}") > limit )); then
        echo "      | ... ($(wc -l < "${file}") lines total)"
    fi
}

# ---------------------------------------------------------------------------
# Setup: put the repo where the scripts expect it
# ---------------------------------------------------------------------------

stage_repo() {
    log "Staging ${REPO_SRC} -> ${ZPREZTO_HOME}"
    rm -rf "${ZPREZTO_HOME}"
    mkdir -p "${ZPREZTO_HOME}"
    # Copy rather than symlink: the scripts write into the tree, and the mount
    # is read-only. .git is skipped (large, and nothing under test reads it).
    tar -C "${REPO_SRC}" --exclude='./.git' --exclude='./tests/.logs' -cf - . \
        | tar -C "${ZPREZTO_HOME}" -xf -
    # A fresh clone has no git-ignored files, so drop them from the copy.
    # Otherwise stale local state (e.g. .config/nvim/lazy-lock.json) is tested
    # instead of what a new machine would actually get.
    git config --global --add safe.directory "${REPO_SRC}" 2>/dev/null
    local ignored
    ignored="$(git -C "${REPO_SRC}" ls-files --others --ignored --exclude-standard 2>/dev/null)"
    if [[ -n "${ignored}" ]]; then
        echo "  dropping $(wc -l <<<"${ignored}") git-ignored file(s) from the copy"
        while IFS= read -r path; do
            [[ -n "${path}" ]] && rm -rf "${ZPREZTO_HOME}/${path}"
        done <<<"${ignored}"
    fi

    # setup.sh runs `git submodule update`; give it a repo so it fails quietly.
    git -C "${ZPREZTO_HOME}" init -q 2>/dev/null
    git -C "${ZPREZTO_HOME}" config user.email "test@example.com" 2>/dev/null
    git -C "${ZPREZTO_HOME}" config user.name "zprezto test" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

test_shell_syntax() {
    log "Shell script syntax"
    local out="/tmp/syntax.log" script

    for script in setup.sh setup-symlinks.sh scripts/install-dev-tools.sh \
                  scripts/install-mono-font.sh scripts/random-quote.sh; do
        [[ -f "${ZPREZTO_HOME}/${script}" ]] || { skip "${script} (missing)"; continue; }
        if zsh -n "${ZPREZTO_HOME}/${script}" >"${out}" 2>&1; then
            pass "zsh -n ${script}"
        else
            fail "zsh -n ${script}"
            show "${out}"
        fi
    done

    for script in runcoms/zshrc runcoms/zshenv runcoms/zprofile runcoms/zlogin \
                  runcoms/zlogout runcoms/zshasyncrc; do
        [[ -f "${ZPREZTO_HOME}/${script}" ]] || { skip "${script} (missing)"; continue; }
        if zsh -n "${ZPREZTO_HOME}/${script}" >"${out}" 2>&1; then
            pass "zsh -n ${script}"
        else
            fail "zsh -n ${script}"
            show "${out}"
        fi
    done

    for script in runcoms/bashrc runcoms/bash_profile runcoms/profile; do
        [[ -f "${ZPREZTO_HOME}/${script}" ]] || { skip "${script} (missing)"; continue; }
        if bash -n "${ZPREZTO_HOME}/${script}" >"${out}" 2>&1; then
            pass "bash -n ${script}"
        else
            fail "bash -n ${script}"
            show "${out}"
        fi
    done
}

test_install_dev_tools() {
    log "scripts/install-dev-tools.sh"
    local out="/tmp/install-dev-tools.log"

    # Answers, in the order the script consumes them:
    #   1 -> the single native package manager available in a container
    #   y -> confirm installing the package list
    #   y -> install upstream neovim if the distro's is too old for the config
    printf '1\ny\ny\n' | zsh "${ZPREZTO_HOME}/scripts/install-dev-tools.sh" >"${out}" 2>&1
    local rc=$?

    if (( rc == 0 )); then
        pass "install-dev-tools.sh exited 0"
    else
        fail "install-dev-tools.sh exited ${rc}"
        show "${out}" 60
        return
    fi

    if grep -qiE 'Unsupported package manager|Invalid selection|No supported package managers' "${out}"; then
        fail "install-dev-tools.sh did not reach an installer"
        show "${out}" 60
        return
    fi

    # Report which of the advertised tools actually ended up callable.
    local core=(git zsh curl)
    local extra=(nvim rg fd bat eza fzf zoxide jq tree htop btop atuin delta mc fish gpg wget)
    # Tools the setup script guarantees, falling back to vendor installers
    # when the distro does not package them.
    local runtimes=(node npm python3 java unzip aws uv)
    local missing_core=() missing_extra=() tool
    export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
    hash -r
    for tool in "${core[@]}";  do command -v "${tool}" >/dev/null 2>&1 || missing_core+=("${tool}"); done
    for tool in "${extra[@]}"; do command -v "${tool}" >/dev/null 2>&1 || missing_extra+=("${tool}"); done

    local missing_runtimes=()
    for tool in "${runtimes[@]}"; do command -v "${tool}" >/dev/null 2>&1 || missing_runtimes+=("${tool}"); done
    if (( ${#missing_runtimes[@]} )); then
        fail "required tools missing after install: ${missing_runtimes[*]}"
    else
        pass "required tools present (${runtimes[*]})"
    fi

    if (( ${#missing_core[@]} )); then
        fail "core tools missing after install: ${missing_core[*]}"
    else
        pass "core tools present"
    fi
    if (( ${#missing_extra[@]} )); then
        warn "tools not on PATH after install (package name differs on ${DISTRO}?): ${missing_extra[*]}"
    else
        pass "all advertised tools on PATH"
    fi
}

test_symlinks() {
    log "setup-symlinks.sh"
    local out="/tmp/symlinks.log"

    # Pre-existing real files and directories are the interesting case: the
    # script used to `rm -RI` them, which silently left them unlinked when the
    # prompt was not answered (uv's installer creates ~/.config/fish, for one).
    mkdir -p "${HOME}/.config/fish/conf.d"
    echo "# pre-existing" > "${HOME}/.config/fish/conf.d/uv.fish"
    echo "# pre-existing" > "${HOME}/.zshrc"

    # No prompts any more, and stdin is closed to prove it stays that way.
    zsh "${ZPREZTO_HOME}/setup-symlinks.sh" </dev/null >"${out}" 2>&1
    local rc=$?
    if (( rc == 0 )); then
        pass "setup-symlinks.sh exited 0"
    else
        fail "setup-symlinks.sh exited ${rc}"
        show "${out}"
    fi

    # Required links, plus optional ones that only apply when the repo
    # actually ships the source file.
    local required=(.bash_profile .bashrc .profile .zlogin .zlogout .zprofile
                    .zshenv .zshrc)
    local optional=(.tmux.conf .tmux.conf.local .tmux)
    local link expected missing=()

    for link in "${required[@]}"; do
        expected="${HOME}/${link}"
        if [[ -L "${expected}" && -e "${expected}" ]]; then
            pass "~/${link} -> $(readlink "${expected}")"
        elif [[ -L "${expected}" ]]; then
            fail "~/${link} is a dangling symlink -> $(readlink "${expected}")"
        else
            missing+=("${link}")
        fi
    done
    (( ${#missing[@]} )) && fail "not symlinked: ${missing[*]}"

    for link in "${optional[@]}"; do
        expected="${HOME}/${link}"
        if [[ ! -e "${ZPREZTO_HOME}/${link}" ]]; then
            if [[ -L "${expected}" ]]; then
                fail "~/${link} links to ${ZPREZTO_HOME}/${link}, which the repo does not ship"
            else
                skip "~/${link} (not in the repo)"
            fi
        elif [[ -L "${expected}" && -e "${expected}" ]]; then
            pass "~/${link} -> $(readlink "${expected}")"
        else
            fail "~/${link} not symlinked"
        fi
    done

    # Pre-existing real configs must be preserved, not destroyed.
    local backups
    backups=$(find "${HOME}" "${HOME}/.config" -maxdepth 1 -name '*.backup.*' 2>/dev/null | wc -l)
    if (( backups >= 2 )); then
        pass "pre-existing ~/.zshrc and ~/.config/fish were backed up (${backups} backups)"
    else
        fail "pre-existing configs were not backed up (found ${backups})"
        ls -la "${HOME}" "${HOME}/.config" 2>/dev/null | sed 's/^/      | /' | head -30
    fi
    if grep -qs '# pre-existing' "${HOME}"/.zshrc.backup.* ; then
        pass "backed up ~/.zshrc still has its original contents"
    else
        fail "backup of ~/.zshrc is missing or empty"
    fi

    # Nothing the script created may dangle.
    local dangling=()
    for expected in "${HOME}"/.[!.]*; do
        [[ -L "${expected}" && ! -e "${expected}" ]] && dangling+=("$(basename "${expected}")")
    done
    if (( ${#dangling[@]} )); then
        fail "dangling symlinks left in \$HOME: ${dangling[*]}"
    else
        pass "no dangling symlinks in \$HOME"
    fi

    # Every directory under .config/ should be linked into ~/.config.
    local item name linked=0 unlinked=()
    for item in "${ZPREZTO_HOME}"/.config/*; do
        name="$(basename "${item}")"
        if [[ -L "${HOME}/.config/${name}" ]]; then
            linked=$((linked + 1))
        else
            unlinked+=("${name}")
        fi
    done
    if (( ${#unlinked[@]} == 0 )); then
        pass "all ${linked} .config entries linked into ~/.config"
    else
        fail "~/.config entries not linked: ${unlinked[*]}"
    fi
}

test_shell_startup() {
    log "Shell startup"
    local out="/tmp/zsh-startup.log"

    zsh -l -i -c 'exit 0' </dev/null >"${out}" 2>&1
    local rc=$?
    if (( rc == 0 )); then
        pass "interactive login zsh starts and exits 0"
    else
        fail "interactive login zsh exited ${rc}"
        show "${out}"
    fi

    # Config errors do not change the exit code, so look at the output too.
    local noise
    noise="$(grep -iE 'not found|no such file|parse error|bad pattern|syntax error' "${out}" \
             | grep -v 'fortune' | head -20)"
    if [[ -z "${noise}" ]]; then
        pass "zsh startup is clean"
    else
        warn "zsh startup prints errors:"
        echo "${noise}" | sed 's/^/      | /'
    fi

    # A handful of things the zshrc is supposed to define.
    local defined
    defined="$(zsh -l -i -c 'whence -w add_to_path source_if_exists ll k 2>/dev/null' </dev/null 2>/dev/null)"
    if grep -q 'add_to_path: function' <<<"${defined}" && grep -q 'll: alias' <<<"${defined}"; then
        pass "zshrc functions and aliases are defined"
    else
        fail "zshrc did not define expected functions/aliases"
        echo "${defined}" | sed 's/^/      | /'
    fi

    bash -l -c 'exit 0' </dev/null >"${out}" 2>&1
    if (( $? == 0 )); then
        pass "login bash starts and exits 0"
    else
        fail "login bash exited $?"
        show "${out}"
    fi
}

nvim_version_ok() {
    local ver major minor
    ver="$(nvim --version 2>/dev/null | head -1 | sed -E 's/^NVIM v?//; s/[^0-9.].*$//')"
    [[ -n "${ver}" ]] || return 1
    major="${ver%%.*}"
    minor="${ver#*.}"; minor="${minor%%.*}"
    (( major > NVIM_MIN_MAJOR )) && return 0
    (( major == NVIM_MIN_MAJOR && minor >= NVIM_MIN_MINOR ))
}

install_upstream_nvim() {
    local arch tarball url out="/tmp/nvim-download.log"
    case "$(uname -m)" in
        x86_64)          arch="linux-x86_64" ;;
        aarch64|arm64)   arch="linux-arm64" ;;
        *) return 1 ;;
    esac
    tarball="nvim-${arch}.tar.gz"
    url="https://github.com/neovim/neovim/releases/download/stable/${tarball}"
    log "Installing upstream neovim (${arch}) from ${url}"
    curl -fsSL -o "/tmp/${tarball}" "${url}" >"${out}" 2>&1 || { show "${out}"; return 1; }
    tar -C /opt -xzf "/tmp/${tarball}" >>"${out}" 2>&1 || { show "${out}"; return 1; }
    ln -sf "/opt/nvim-${arch}/bin/nvim" /usr/local/bin/nvim
    hash -r
    return 0
}

ensure_nvim() {
    case "${NVIM_SOURCE}" in
        upstream)
            install_upstream_nvim || return 1
            ;;
        distro)
            command -v nvim >/dev/null 2>&1 || return 1
            ;;
        auto)
            if ! command -v nvim >/dev/null 2>&1 || ! nvim_version_ok; then
                install_upstream_nvim || return 1
            fi
            ;;
    esac
    return 0
}

# Every plugin in lua/plugins must actually load and expose its module.
test_nvim_plugins() {
    local out="/tmp/nvim-plugins.log"
    log "  plugin modules"

    timeout 300 nvim --headless -c 'lua
      local modules = {
        ["lazy"] = "lazy.nvim",
        ["telescope"] = "telescope.nvim",
        ["telescope._extensions.fzf"] = "telescope-fzf-native (compiled)",
        ["nvim-tree"] = "nvim-tree.lua",
        ["lualine"] = "lualine.nvim",
        ["bufferline"] = "bufferline.nvim",
        ["toggleterm"] = "toggleterm.nvim",
        ["auto-session"] = "auto-session",
        ["cmp"] = "nvim-cmp",
        ["luasnip"] = "LuaSnip",
        ["nvim-treesitter"] = "nvim-treesitter",
        ["mason"] = "mason.nvim",
        ["mason-lspconfig"] = "mason-lspconfig.nvim",
        ["jdtls"] = "nvim-jdtls",
        ["monokai"] = "monokai.nvim",
      }
      local failed = {}
      for module, label in pairs(modules) do
        local ok, err = pcall(require, module)
        if not ok then table.insert(failed, label .. " (" .. module .. "): " .. tostring(err):gsub("\n.*", "")) end
      end
      if #failed == 0 then
        print("PLUGINS_OK")
      else
        print("PLUGINS_FAILED:")
        for _, f in ipairs(failed) do print("  " .. f) end
      end' +qa </dev/null >"${out}" 2>&1

    if grep -q 'PLUGINS_OK' "${out}"; then
        pass "all plugin modules load"
    else
        fail "some plugin modules do not load"
        show "${out}" 30
    fi

    # The colorscheme and statusline should actually be applied, not just loadable.
    timeout 120 nvim --headless -c 'lua
      print("COLORSCHEME=" .. (vim.g.colors_name or "none"))
      print("STATUSLINE=" .. (vim.o.statusline ~= "" and "set" or "unset"))
      print("TABLINE=" .. (vim.o.tabline ~= "" and "set" or "unset"))' \
      +qa </dev/null >"${out}" 2>&1
    if grep -qE 'COLORSCHEME=(monokai|none)' "${out}" && ! grep -q 'COLORSCHEME=none' "${out}"; then
        pass "colorscheme applied ($(grep -o 'COLORSCHEME=.*' "${out}"))"
    else
        warn "no colorscheme applied"
    fi
    if grep -q 'STATUSLINE=set' "${out}"; then
        pass "lualine set the statusline"
    else
        fail "statusline was not set by lualine"
        show "${out}" 20
    fi
    if grep -q 'TABLINE=set' "${out}"; then
        pass "bufferline set the tabline"
    else
        fail "tabline was not set by bufferline"
        show "${out}" 20
    fi
}

# Mason has to reach its registry and install the servers in ensure_installed.
test_nvim_mason() {
    local out="/tmp/nvim-mason.log"
    log "  mason"

    timeout 300 nvim --headless -c 'lua
      local ok, registry = pcall(require, "mason-registry")
      if not ok then print("REGISTRY_FAILED: " .. tostring(registry)) return end
      registry.refresh()
      local packages = registry.get_all_package_names()
      print("REGISTRY_PACKAGES=" .. #packages)' +qa </dev/null >"${out}" 2>&1

    local count
    count="$(grep -oE 'REGISTRY_PACKAGES=[0-9]+' "${out}" | cut -d= -f2)"
    if [[ -n "${count}" ]] && (( count > 100 )); then
        pass "mason registry reachable (${count} packages)"
    else
        fail "mason registry not reachable"
        show "${out}" 20
        return
    fi

    # MasonInstall blocks in headless mode, so this is a real install.
    log "    installing language servers (lua, python, java)"
    timeout 1200 nvim --headless \
        -c 'MasonInstall lua-language-server pyright jdtls' -c 'qall' \
        </dev/null >"${out}" 2>&1
    local rc=$?
    if (( rc == 124 )); then
        fail "MasonInstall timed out after 1200s"
        show "${out}" 30
        return
    fi

    local bin_dir="${HOME}/.local/share/nvim/mason/bin" server
    for server in lua-language-server pyright-langserver jdtls; do
        if [[ -x "${bin_dir}/${server}" ]]; then
            pass "mason installed ${server}"
        else
            fail "mason did not install ${server}"
            show "${out}" 30
        fi
    done
}

# The servers must attach to a real buffer, not merely be installed.
test_nvim_lsp() {
    local out="/tmp/nvim-lsp.log"
    log "  language servers attach"

    local workdir="/tmp/lsp-project"
    rm -rf "${workdir}"
    mkdir -p "${workdir}/src/main/java/demo"
    git -C "${workdir}" init -q

    cat > "${workdir}/sample.py" <<'PYFILE'
def greet(name: str) -> str:
    return "hello " + name
PYFILE

    cat > "${workdir}/src/main/java/demo/Sample.java" <<'JAVAFILE'
package demo;

public class Sample {
    public static void main(String[] args) {
        System.out.println("hello");
    }
}
JAVAFILE

    cat > "${workdir}/sample.lua" <<'LUAFILE'
local M = {}
function M.greet(name) return "hello " .. name end
return M
LUAFILE

    # Each language gets its own nvim run so one failure cannot mask another.
    local lang file want timeout_s
    for lang in lua python java; do
        case "${lang}" in
            lua)    file="sample.lua";                       want="lua_ls";   timeout_s=90 ;;
            python) file="sample.py";                        want="pyright";  timeout_s=90 ;;
            java)   file="src/main/java/demo/Sample.java";   want="jdtls";    timeout_s=300 ;;
        esac

        (cd "${workdir}" && timeout $((timeout_s + 60)) nvim --headless "${file}" \
            -c "lua
              local want = '${want}'
              local deadline = ${timeout_s} * 1000
              local attached = vim.wait(deadline, function()
                return #vim.lsp.get_clients({ bufnr = 0 }) > 0
              end, 200)
              local names = {}
              for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
                table.insert(names, c.name)
              end
              if not attached then
                print('LSP_NONE want=' .. want)
              else
                print('LSP_ATTACHED=' .. table.concat(names, ','))
              end" \
            -c 'messages' -c 'qa!' </dev/null) >"${out}" 2>&1

        if grep -q "LSP_ATTACHED=.*${want}" "${out}"; then
            pass "${lang}: ${want} attached"
        elif grep -q 'LSP_ATTACHED=' "${out}"; then
            fail "${lang}: expected ${want}, got $(grep -o 'LSP_ATTACHED=.*' "${out}")"
            show "${out}" 25
        else
            fail "${lang}: no language server attached (wanted ${want})"
            show "${out}" 25
        fi
    done
}

test_nvim() {
    log "Neovim config"

    if ! ensure_nvim; then
        fail "could not obtain a usable neovim"
        return
    fi

    local version
    version="$(nvim --version | head -1)"
    if nvim_version_ok; then
        pass "${version} (>= ${NVIM_MIN_MAJOR}.${NVIM_MIN_MINOR}, from $(command -v nvim))"
    else
        fail "${version} is older than the ${NVIM_MIN_MAJOR}.${NVIM_MIN_MINOR} the config requires"
        return
    fi

    if [[ ! -L "${HOME}/.config/nvim" ]]; then
        fail "~/.config/nvim is not symlinked to the repo"
        return
    fi

    local out="/tmp/nvim-sync.log"
    log "  lazy.nvim sync (clones plugins, may take a few minutes)"
    timeout 900 nvim --headless "+Lazy! sync" +qa </dev/null >"${out}" 2>&1
    local rc=$?
    if (( rc == 124 )); then
        fail "Lazy sync timed out after 900s"
        show "${out}"
        return
    fi
    # Lazy streams git progress (megabytes of it) to stderr, so strip the
    # escape codes and carriage returns and look only for real errors.
    local clean="/tmp/nvim-sync.clean.log" errors
    sed -e 's/\x1b\[[0-9;]*[a-zA-Z]//g' "${out}" | tr '\r' '\n' > "${clean}"
    errors="$(grep -aE 'E[0-9]{2,4}:|stack traceback|attempt to (index|call)|Failed to run|✗' "${clean}" \
              | sort -u | head -20)"
    if [[ -z "${errors}" ]]; then
        pass "Lazy sync completed (exit ${rc})"
    else
        fail "Lazy sync reported errors"
        echo "${errors}" | sed 's/^/      | /'
    fi

    local deprecations
    deprecations="$(grep -aoE '[a-zA-Z_.]+\(\) is deprecated' "${clean}" | sort -u | head -10)"
    [[ -n "${deprecations}" ]] && warn "deprecated neovim APIs used by the config: $(echo ${deprecations} | tr '\n' ' ')"

    local lazy_dir="${HOME}/.local/share/nvim/lazy" count
    count=$(find "${lazy_dir}" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)
    if (( count >= 10 )); then
        pass "${count} plugins installed under ${lazy_dir}"
    else
        fail "only ${count} plugins installed under ${lazy_dir}"
    fi

    # Every spec in lua/plugins must have produced a loadable plugin.
    out="/tmp/nvim-check.log"
    timeout 300 nvim --headless -c 'lua
      local ok, lazy = pcall(require, "lazy")
      if not ok then print("LAZY_MISSING") vim.cmd("cq") end
      local missing = {}
      for _, p in ipairs(lazy.plugins()) do
        if not p._.installed then table.insert(missing, p.name) end
      end
      if #missing > 0 then
        print("MISSING: " .. table.concat(missing, ", "))
      else
        print("ALL_INSTALLED " .. #lazy.plugins())
      end' +qa </dev/null >"${out}" 2>&1
    if grep -q 'ALL_INSTALLED' "${out}"; then
        pass "$(grep -o 'ALL_INSTALLED.*' "${out}" | sed 's/ALL_INSTALLED/all/') plugin specs installed"
    else
        fail "some plugin specs are not installed"
        show "${out}" 30
    fi

    # Start on a real file: exercises ftplugin, treesitter, lualine, LSP attach.
    out="/tmp/nvim-open.log"
    cat > /tmp/sample.lua <<'LUA'
local function greet(name)
  return "hello " .. name
end
return greet
LUA
    timeout 300 nvim --headless /tmp/sample.lua \
        -c 'lua vim.wait(3000, function() return false end)' \
        -c 'lua print("FILETYPE=" .. vim.bo.filetype)' \
        -c 'lua print("FOLDEXPR=" .. vim.o.foldexpr)' \
        -c 'lua print("LEADER=" .. vim.g.mapleader)' \
        -c 'messages' -c 'qa' </dev/null >"${out}" 2>&1
    if grep -q 'FILETYPE=lua' "${out}"; then
        pass "opens a lua file with the expected filetype"
    else
        fail "opening a lua file did not report filetype=lua"
        show "${out}" 40
    fi
    if grep -q 'foldexpr()' "${out}"; then
        pass "treesitter foldexpr is active"
    else
        warn "treesitter foldexpr not reported"
    fi
    if grep -qE 'E[0-9]+:|stack traceback|attempt to (index|call) a nil' "${out}"; then
        fail "errors while editing a file"
        show "${out}" 40
    else
        pass "no errors while editing a file"
    fi

    # The config installs parsers asynchronously, so drive it synchronously
    # here: this is what actually proves parser compilation works.
    out="/tmp/nvim-parsers.log"
    log "  treesitter parser install"
    timeout 900 nvim --headless -c 'lua
      local ts = require("nvim-treesitter")
      local want = { "lua", "python", "java", "bash", "json" }
      local ok, err = pcall(function() ts.install(want):wait(600000) end)
      if not ok then print("INSTALL_FAILED: " .. tostring(err)) return end
      local missing = {}
      for _, lang in ipairs(want) do
        if not pcall(vim.treesitter.language.add, lang) then
          table.insert(missing, lang)
        end
      end
      print(#missing == 0 and ("PARSERS_OK " .. #want)
            or ("PARSERS_MISSING: " .. table.concat(missing, " ")))' \
      +qa </dev/null >"${out}" 2>&1
    if grep -q 'PARSERS_OK' "${out}"; then
        pass "$(grep -o 'PARSERS_OK [0-9]*' "${out}" | awk '{print $2}') treesitter parsers compiled and loadable"
    else
        fail "treesitter parsers did not install"
        show "${out}" 30
    fi

    # Highlighting must actually turn on for an installed parser.
    out="/tmp/nvim-highlight.log"
    timeout 300 nvim --headless /tmp/sample.lua \
        -c 'lua vim.wait(2000, function() return vim.treesitter.highlighter.active[0] ~= nil end)' \
        -c 'lua print("HIGHLIGHT=" .. tostring(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil))' \
        -c 'qa' </dev/null >"${out}" 2>&1
    if grep -q 'HIGHLIGHT=true' "${out}"; then
        pass "treesitter highlighting active on a lua buffer"
    else
        fail "treesitter highlighting not active"
        show "${out}" 25
    fi

    test_nvim_plugins
    test_nvim_mason
    test_nvim_lsp

    # Keymaps defined in init.lua.
    out="/tmp/nvim-keymap.log"
    timeout 120 nvim --headless -c 'lua
      local leader = vim.g.mapleader or "\\"
      local want = { n = { "<C-h>", "<C-j>", "<S-l>", "<S-h>", "gt", leader .. "bd" },
                     i = { "jk" },
                     v = { "J", "K" } }
      local missing = {}
      for mode, keys in pairs(want) do
        for _, k in ipairs(keys) do
          -- maparg normalises <C-h>/<C-H> and resolves <leader>.
          if vim.fn.maparg(vim.api.nvim_replace_termcodes(k, true, true, true), mode) == "" and
             vim.fn.maparg(k, mode) == "" then
            table.insert(missing, mode .. ":" .. k)
          end
        end
      end
      print(#missing == 0 and "KEYMAPS_OK" or ("KEYMAPS_MISSING: " .. table.concat(missing, " ")))' \
      +qa </dev/null >"${out}" 2>&1
    if grep -q 'KEYMAPS_OK' "${out}"; then
        pass "init.lua keymaps are registered"
    else
        fail "init.lua keymaps missing"
        show "${out}" 20
    fi
}

test_setup_sh() {
    log "setup.sh (end to end)"
    local out="/tmp/setup.log"

    # Answers, in the order setup.sh consumes them:
    #   n  -> skip the LunarVim installer (huge, and independent of this repo)
    #   1  -> the single native package manager offered by install-dev-tools.sh
    #   y  -> confirm installing the package list
    #   y  -> install upstream neovim if the distro's is too old
    #   y  -> install starship
    printf 'n\n1\ny\ny\ny\n' | timeout 1800 zsh "${ZPREZTO_HOME}/setup.sh" >"${out}" 2>&1
    local rc=$?
    if (( rc == 0 )); then
        pass "setup.sh exited 0"
    else
        fail "setup.sh exited ${rc}"
    fi
    show "${out}" 80

    local thing
    for thing in "${HOME}/.zshrc" "${HOME}/.tmux/plugins/tpm" "${HOME}/.fzf"; do
        if [[ -e "${thing}" ]]; then
            pass "setup.sh produced ${thing}"
        else
            fail "setup.sh did not produce ${thing}"
        fi
    done
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

echo
echo -e "${BLUE}=======================================================${NC}"
echo -e "${BLUE} zprezto container tests — distro=${DISTRO} mode=${MODE}${NC}"
echo -e "${BLUE}=======================================================${NC}"
echo "  $(cat /etc/os-release 2>/dev/null | grep -E '^PRETTY_NAME' | cut -d'"' -f2)  ($(uname -m))"
echo "  zsh $(zsh --version 2>/dev/null | awk '{print $2}')"
echo

stage_repo

test_shell_syntax

if [[ "${MODE}" == "full" ]]; then
    test_setup_sh
    test_symlinks
    test_shell_startup
    test_nvim
elif [[ "${MODE}" == "quick" ]]; then
    skip "install-dev-tools.sh (quick mode)"
    test_symlinks
    test_shell_startup
    skip "neovim plugin sync (quick mode)"
else
    test_install_dev_tools
    test_symlinks
    test_shell_startup
    test_nvim
fi

echo
echo -e "${BLUE}------------------- summary (${DISTRO}) -------------------${NC}"
echo -e "  ${GREEN}passed:  ${PASSED}${NC}"
echo -e "  ${YELLOW}warned:  ${WARNED}${NC}"
echo -e "  ${CYAN}skipped: ${SKIPPED}${NC}"
echo -e "  ${RED}failed:  ${FAILED}${NC}"
if (( WARNED )); then
    printf '    warn: %s\n' "${WARNED_NAMES[@]}"
fi
if (( FAILED )); then
    printf '    fail: %s\n' "${FAILED_NAMES[@]}"
    echo -e "${RED}RESULT: FAIL (${DISTRO})${NC}"
    exit 1
fi
echo -e "${GREEN}RESULT: PASS (${DISTRO})${NC}"
exit 0
