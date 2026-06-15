# Multi-repo VS Code workspace helpers
# Source this file from ~/.zshrc, for example:
#   source ~/bin/multi-repo-workspace.zsh
#
# Exported function prefix: mw_
#
# Assumptions:
# - A "repo" is any direct child directory containing a .git directory or file.
# - Commands run from the workspace root unless --workspace is provided.
# - Git remotes are expected to use origin for ahead/behind and upstream setup.

# Field delimiter between repo-table columns (passed to column(1) -s). Default is TAB; set
# before sourcing to override, e.g. WS_REPO_TABLE_SEP='|'. Prefer a single character.
: "${WS_REPO_TABLE_SEP:=$'\t'}"

# -----------------------------
# Internal helpers
# -----------------------------

# Git status / count glyphs.
_ws_git_sym_conflicted='='
_ws_git_sym_ahead='⇡'
_ws_git_sym_behind='⇣'
_ws_git_sym_diverged='⇕'
_ws_git_sym_untracked='?'
_ws_git_sym_stashed='$'
_ws_git_sym_modified='!'
_ws_git_sym_staged='+'
_ws_git_sym_renamed='»'
_ws_git_sym_deleted='✘'

# Private-use / dingbat glyphs (single assignment each; callers use these names only).
_ws_glyph_nf_git_branch=$'\uF126 '   # Nerd Font devicons branch; matches p10k VCS_BRANCH_ICON
_ws_glyph_nf_cod_repo=$'\uEA62 '    # Codicons repo, upstream column prefix
_ws_glyph_check_mark=$'\u2713 '     # heavy check mark (fetch/pull/push ok line prefix)
_ws_glyph_ballot_x=$'\u2717 '       # ballot X (failed line prefix)

_ws_usage_common_workspace() {
  cat <<'EOF'
Common options:
  -w, --workspace DIR   Workspace root. Defaults to current directory.
  -v, --verbose         Print extra details.
  -h, --help            Show help.
EOF
}

_ws_die() {
  print -u2 -- "mw: $*"
  return 1
}

# Set WS_DEBUG=1 (or any non-empty value) to trace ws_list and its helpers on stderr.
_ws_debug() {
  [[ -n "${WS_DEBUG:-}" ]] || return 0
  print -u2 -- "[ws-debug] $*"
}

_ws_workspace_root() {
  local workspace="$1"

  _ws_debug "_ws_workspace_root: arg workspace=${workspace:-<empty>}, PWD=$PWD"

  if [[ -z "$workspace" ]]; then
    workspace="$PWD"
  fi

  if [[ ! -d "$workspace" ]]; then
    _ws_debug "_ws_workspace_root: not a directory: $workspace"
    _ws_die "workspace does not exist: $workspace"
    return 1
  fi

  if ! builtin cd "$workspace" >/dev/null 2>&1; then
    _ws_debug "_ws_workspace_root: cd failed: $workspace"
    return 1
  fi

  local resolved
  resolved="$(pwd -P)"
  _ws_debug "_ws_workspace_root: resolved root=$resolved"
  print -r -- "$resolved"
}

_ws_repo_dirs() {
  local workspace="$1"
  local dir

  _ws_debug "_ws_repo_dirs: workspace=$workspace"

  if [[ ! -d "$workspace" ]]; then
    _ws_debug "_ws_repo_dirs: workspace is not a directory, glob will be empty"
  fi

  local -a candidates
  candidates=("$workspace"/*(N/))
  _ws_debug "_ws_repo_dirs: child dirs matching */(N/): count=${#candidates[@]}"

  for dir in "${candidates[@]}"; do
    if [[ -e "$dir/.git" ]]; then
      _ws_debug "_ws_repo_dirs: include $dir (.git present)"
      print -r -- "$dir"
    else
      _ws_debug "_ws_repo_dirs: skip $dir (no .git)"
    fi
  done
}

_ws_has_repos() {
  local -a repos
  repos=("$@")

  _ws_debug "_ws_has_repos: argc=${#repos[@]} args=${repos[*]:-<none>}"

  if (( ${#repos[@]} == 0 )); then
    _ws_debug "_ws_has_repos: failing — zero repos (check _ws_repo_dirs and ws_list repos= assignment)"
    _ws_die "no git repositories found"
    return 1
  fi
}

_ws_repo_name() {
  basename "$1"
}

_ws_current_branch() {
  git -C "$1" symbolic-ref --quiet --short HEAD 2>/dev/null \
    || git -C "$1" rev-parse --short HEAD 2>/dev/null \
    || print -- "unknown"
}

_ws_stash_count() {
  git -C "$1" stash list 2>/dev/null | wc -l | tr -d ' '
}

_ws_dirty_status() {
  local repo="$1"
  local porcelain
  porcelain="$(git -C "$repo" status --porcelain=v1 2>/dev/null)"

  if [[ -z "$porcelain" ]]; then
    print -- "clean"
    return 0
  fi

  local has_staged="no"
  local has_unstaged="no"
  local line index_status worktree_status

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    index_status="${line[1,1]}"
    worktree_status="${line[2,2]}"

    # Untracked files show as ??, which are unstaged for practical purposes.
    if [[ "$index_status" == "?" && "$worktree_status" == "?" ]]; then
      has_unstaged="yes"
      continue
    fi

    [[ "$index_status" != " " ]] && has_staged="yes"
    [[ "$worktree_status" != " " ]] && has_unstaged="yes"
  done <<< "$porcelain"

  if [[ "$has_staged" == "yes" && "$has_unstaged" == "yes" ]]; then
    print -- "staged+unstaged"
  elif [[ "$has_staged" == "yes" ]]; then
    print -- "staged"
  elif [[ "$has_unstaged" == "yes" ]]; then
    print -- "unstaged"
  else
    print -- "dirty"
  fi
}

_ws_ahead_behind() {
  local repo="$1"
  local upstream

  upstream="$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"
  if [[ -z "$upstream" ]]; then
    print -- "0 0 none"
    return 0
  fi

  local counts ahead behind
  counts="$(git -C "$repo" rev-list --left-right --count HEAD..."$upstream" 2>/dev/null)"

  if [[ -z "$counts" ]]; then
    print -- "0 0 $upstream"
    return 0
  fi

  ahead="${counts%%[[:space:]]*}"
  behind="${counts##*[[:space:]]}"
  print -- "$ahead $behind $upstream"
}

_ws_has_origin_main() {
  git -C "$1" rev-parse -q --verify refs/remotes/origin/main >/dev/null 2>&1
}

# Prints two fields: ahead behind for HEAD vs origin/main (three-dot symmetric difference).
# Returns 1 when origin/main is missing.
_ws_ahead_behind_origin_main() {
  local repo="$1" counts ahead behind

  if ! _ws_has_origin_main "$repo"; then
    return 1
  fi

  counts="$(git -C "$repo" rev-list --left-right --count HEAD...refs/remotes/origin/main 2>/dev/null)"
  if [[ -z "$counts" ]]; then
    print -- "0 0"
    return 0
  fi

  ahead="${counts%%[[:space:]]*}"
  behind="${counts##*[[:space:]]}"
  print -- "$ahead $behind"
}

_ws_branch_exists() {
  local repo="$1"
  local branch="$2"

  git -C "$repo" show-ref --verify --quiet "refs/heads/$branch" \
    || git -C "$repo" show-ref --verify --quiet "refs/remotes/origin/$branch"
}

# Strip characters that break repo-table / column(1) alignment (separator, tabs, newlines).
_ws_tsv_escape() {
  local s="${1:-}" sep="${WS_REPO_TABLE_SEP}"
  [[ -n "$sep" ]] && s="${s//$sep/ }"
  s="${s//$'\t'/ }"
  s="${s//$'\n'/ }"
  s="${s//$'\r'/ }"
  print -rn -- "$s"
}

# Pipe delimiter-separated repo table lines through column(1) -t (BSD/GNU columnate; zsh has no column builtin).
_ws_repo_table_columnize() {
  if command -v column >/dev/null 2>&1; then
    command column -t -s "$WS_REPO_TABLE_SEP"
  else
    cat
  fi
}

# Same codepoint as POWERLEVEL9K_VCS_BRANCH_ICON in runcoms/p10k.zsh (Nerd Font).
_ws_nf_branch_icon() {
  print -rn -- "$_ws_glyph_nf_git_branch"
}

# Codicon repo before upstream ref; narrow terminals may misalign wide glyphs.
_ws_nf_upstream_icon() {
  print -rn -- "$_ws_glyph_nf_cod_repo"
}

# Header row for column(1), fields joined with WS_REPO_TABLE_SEP. Optional $1: non-empty => trailing "op" column.
# Output is meant to be piped with data rows through _ws_repo_table_columnize.
_ws_print_repo_list_header() {
  local with_op="${1:-}" sep="$WS_REPO_TABLE_SEP"

  if [[ -n "$with_op" ]]; then
    print -r -- "repo${sep}branch${sep}status${sep}stash${sep}ahead${sep}behind${sep}upstream${sep}op"
  else
    print -r -- "repo${sep}branch${sep}status${sep}stash${sep}ahead${sep}behind${sep}upstream"
  fi
}

# One delimiter-separated repo row for column(1). Optional line_icon prefixes the repo field;
# optional custom_col is the last field when has_op_col is 1 (fetch/pull/push tables).
# Stash / ahead / behind use _ws_git_sym_*; status line gets symbol hints.
# Fourth arg has_op_col: 1 = eight columns (…, op); 0 = seven columns (ws_list / ws_branch).
_ws_print_repo_status() {
  emulate -L zsh
  local repo_path="${1:?}"
  local line_icon="${2:-}"
  local custom_col="${3:-}"
  local has_op_col="${4:-0}"

  local name branch dirty_state stash ab ahead behind upstream
  name="$(_ws_repo_name "$repo_path")"
  branch="$(_ws_current_branch "$repo_path")"
  dirty_state="$(_ws_dirty_status "$repo_path")"
  stash="$(_ws_stash_count "$repo_path")"
  ab="$(_ws_ahead_behind "$repo_path")"
  ahead="${ab[(w)1]}"
  behind="${ab[(w)2]}"
  upstream="${ab[(w)3]}"

  local nf_branch nf_up
  nf_branch="$(_ws_nf_branch_icon)"
  nf_up="$(_ws_nf_upstream_icon)"

  local repo_cell status_disp stash_disp ahead_disp behind_disp
  repo_cell="${line_icon}${name}"

  status_disp="$dirty_state"
  case "$dirty_state" in
    staged)         status_disp+=" ${_ws_git_sym_staged}" ;;
    unstaged)       status_disp+=" ${_ws_git_sym_modified}" ;;
    staged+unstaged) status_disp+=" ${_ws_git_sym_staged}${_ws_git_sym_modified}" ;;
    dirty)          status_disp+=" ${_ws_git_sym_modified}" ;;
  esac

  stash_disp="$stash"
  (( ${stash:-0} > 0 )) && stash_disp="${_ws_git_sym_stashed}${stash}"

  ahead_disp="$ahead"
  behind_disp="$behind"
  if (( ${ahead:-0} > 0 && ${behind:-0} > 0 )); then
    ahead_disp="${_ws_git_sym_diverged}${ahead}/${behind}"
    behind_disp=''
  else
    (( ${ahead:-0} > 0 )) && ahead_disp="${_ws_git_sym_ahead}${ahead}"
    (( ${behind:-0} > 0 )) && behind_disp="${_ws_git_sym_behind}${behind}"
  fi

  local b up sep="$WS_REPO_TABLE_SEP"
  b="${nf_branch}${branch}"
  up="${nf_up}${upstream}"

  repo_cell="$(_ws_tsv_escape "$repo_cell")"
  b="$(_ws_tsv_escape "$b")"
  status_disp="$(_ws_tsv_escape "$status_disp")"
  stash_disp="$(_ws_tsv_escape "$stash_disp")"
  ahead_disp="$(_ws_tsv_escape "$ahead_disp")"
  behind_disp="$(_ws_tsv_escape "$behind_disp")"
  up="$(_ws_tsv_escape "$up")"

  if [[ "$has_op_col" == 1 ]]; then
    print -r -- "${repo_cell}${sep}${b}${sep}${status_disp}${sep}${stash_disp}${sep}${ahead_disp}${sep}${behind_disp}${sep}${up}${sep}$(_ws_tsv_escape "${custom_col:-}")"
  else
    print -r -- "${repo_cell}${sep}${b}${sep}${status_disp}${sep}${stash_disp}${sep}${ahead_disp}${sep}${behind_disp}${sep}${up}"
  fi
}

_ws_confirm() {
  local prompt="$1"
  local answer

  printf "%s [y/N] " "$prompt"
  read -r answer

  [[ "$answer" == "y" || "$answer" == "Y" || "$answer" == "yes" || "$answer" == "YES" ]]
}

# -----------------------------
# Exported functions
# -----------------------------

ws_list() {
  emulate -L zsh
  setopt pipefail

  local -a opt_workspace opt_verbose opt_help
  zparseopts -D -E \
    {w,-workspace}:=opt_workspace \
    {v,-verbose}=opt_verbose \
    {h,-help}=opt_help || return 2

  if (( ${#opt_help[@]} )); then
    cat <<'EOF'
Usage:
  ws_list [-w DIR] [-v]

Lists every repo in a table with:
  - repo name (optional line icon callers may embed in the repo cell)
  - current branch (Nerd Font branch glyph, same as p10k)
  - clean/staged/unstaged status (starship-style + ! = hints where applicable)
  - stash / ahead / behind (starship-style $ ⇡ ⇣ ⇕ glyphs)
  - upstream (repo glyph prefix)
  - columns aligned with column(1) -t (see WS_REPO_TABLE_SEP for the field delimiter)
EOF
    _ws_usage_common_workspace
    return 0
  fi

  local workspace
  workspace="$(_ws_workspace_root "${opt_workspace[-1]}")" || return 1

  _ws_debug "ws_list: resolved workspace=$workspace"

  local repo_dirs_raw
  repo_dirs_raw="$(_ws_repo_dirs "$workspace")"
  _ws_debug "ws_list: raw _ws_repo_dirs output (between markers):"
  _ws_debug "ws_list: ---8<---"
  while IFS= read -r line || [[ -n "$line" ]]; do
    _ws_debug "ws_list: | $line"
  done <<< "$repo_dirs_raw"
  _ws_debug "ws_list: ---8<--- (end raw)"

  local -a repos
  repos=("${(@f)repo_dirs_raw}")
  _ws_debug "ws_list: repos array length=${#repos[@]} elements: ${repos[*]:-<empty>}"

  _ws_has_repos "${repos[@]}" || return 1

  {
    _ws_print_repo_list_header
    local repo
    for repo in "${repos[@]}"; do
      _ws_debug "ws_list: processing repo path=$repo"
      _ws_print_repo_status "$repo" '' '' 0
    done
  } | _ws_repo_table_columnize
}

ws_fetch() {
  emulate -L zsh
  setopt pipefail

  local -a opt_workspace opt_verbose opt_help opt_prune
  zparseopts -D -E \
    {w,-workspace}:=opt_workspace \
    {v,-verbose}=opt_verbose \
    {p,-prune}=opt_prune \
    {h,-help}=opt_help || return 2

  if (( ${#opt_help[@]} )); then
    cat <<'EOF'
Usage:
  ws_fetch [-w DIR] [-p] [-v]

Runs git fetch in every repo, then prints the same per-repo table as ws_list
with a trailing op column (ok / failed). Optional check/cross is prefixed in the
repo name column.

Options:
  -p, --prune           Run git fetch --prune.
EOF
    _ws_usage_common_workspace
    return 0
  fi

  local workspace
  workspace="$(_ws_workspace_root "${opt_workspace[-1]}")" || return 1

  local -a repos fetch_args
  repos=("${(@f)$(_ws_repo_dirs "$workspace")}")
  _ws_has_repos "${repos[@]}" || return 1

  fetch_args=(fetch)
  (( ${#opt_prune[@]} )) && fetch_args+=(--prune)

  {
    _ws_print_repo_list_header 1
    local repo name fetch_rc
    for repo in "${repos[@]}"; do
      name="$(_ws_repo_name "$repo")"

      if (( ${#opt_verbose[@]} )); then
        print -u2 -- "\n==> $name"
        git -C "$repo" "${fetch_args[@]}"
      else
        git -C "$repo" "${fetch_args[@]}" >/dev/null 2>&1
      fi
      fetch_rc=$?

      if (( fetch_rc == 0 )); then
        _ws_print_repo_status "$repo" "$_ws_glyph_check_mark" ok 1
      else
        print -u2 -- "ws_fetch: git fetch failed in $name (exit $fetch_rc)"
        _ws_print_repo_status "$repo" "$_ws_glyph_ballot_x" failed 1
      fi
    done
  } | _ws_repo_table_columnize
}

ws_pull() {
  emulate -L zsh
  setopt pipefail

  local -a opt_workspace opt_verbose opt_help opt_rebase
  zparseopts -D -E \
    {w,-workspace}:=opt_workspace \
    {v,-verbose}=opt_verbose \
    {r,-rebase}=opt_rebase \
    {h,-help}=opt_help || return 2

  if (( ${#opt_help[@]} )); then
    cat <<'EOF'
Usage:
  ws_pull [-w DIR] [-r] [-v]

Runs git pull in every repo, then prints the same per-repo table as ws_list
with a trailing op column (ok / failed).

Options:
  -r, --rebase          Run git pull --rebase.
EOF
    _ws_usage_common_workspace
    return 0
  fi

  local workspace
  workspace="$(_ws_workspace_root "${opt_workspace[-1]}")" || return 1

  local -a repos pull_args
  repos=("${(@f)$(_ws_repo_dirs "$workspace")}")
  _ws_has_repos "${repos[@]}" || return 1

  pull_args=(pull)
  (( ${#opt_rebase[@]} )) && pull_args+=(--rebase)

  {
    _ws_print_repo_list_header 1
    local repo name pull_rc
    for repo in "${repos[@]}"; do
      name="$(_ws_repo_name "$repo")"

      if (( ${#opt_verbose[@]} )); then
        print -u2 -- "\n==> $name"
        git -C "$repo" "${pull_args[@]}"
      else
        git -C "$repo" "${pull_args[@]}" >/dev/null 2>&1
      fi
      pull_rc=$?

      if (( pull_rc == 0 )); then
        _ws_print_repo_status "$repo" "$_ws_glyph_check_mark" ok 1
      else
        print -u2 -- "ws_pull: git pull failed in $name (exit $pull_rc)"
        _ws_print_repo_status "$repo" "$_ws_glyph_ballot_x" failed 1
      fi
    done
  } | _ws_repo_table_columnize
}

ws_push() {
  emulate -L zsh
  setopt pipefail

  local -a opt_workspace opt_verbose opt_help
  zparseopts -D -E \
    {w,-workspace}:=opt_workspace \
    {v,-verbose}=opt_verbose \
    {h,-help}=opt_help || return 2

  if (( ${#opt_help[@]} )); then
    cat <<'EOF'
Usage:
  ws_push [-w DIR] [-v]

Runs git push in every repo (git push -u origin HEAD when no upstream is set).
When it prints per-repo output, uses the same table as ws_list with a trailing
op column (ok, failed, or no changes). Line icons sit in the repo column.

Preflight:
  - Aborts if any repo is on branch main with a non-clean working tree.
  - If every repo has origin/main and each HEAD is neither ahead nor behind
    origin/main, exits with message: no changes to push.
  - If no repo has local commits to push (ahead of @{u} is 0 and upstream is set),
    or only main with a clean tree and nothing ahead of upstream, exits with:
    no changes to push.
  - Repos on main with a clean tree and nothing ahead of upstream are skipped
    per repo (no changes to push).
EOF
    _ws_usage_common_workspace
    return 0
  fi

  local workspace
  workspace="$(_ws_workspace_root "${opt_workspace[-1]}")" || return 1

  local -a repos
  repos=("${(@f)$(_ws_repo_dirs "$workspace")}")
  _ws_has_repos "${repos[@]}" || return 1

  local repo name branch dirty_state ab ahead upstream main_ab ma mb
  for repo in "${repos[@]}"; do
    branch="$(_ws_current_branch "$repo")"
    dirty_state="$(_ws_dirty_status "$repo")"
    if [[ "$branch" == "main" && "$dirty_state" != "clean" ]]; then
      _ws_die "ws_push: non-clean working tree on main in $(_ws_repo_name "$repo"); aborting"
      return 1
    fi
  done

  local all_have_origin_main=1 all_synced_with_main=1
  for repo in "${repos[@]}"; do
    if ! _ws_has_origin_main "$repo"; then
      all_have_origin_main=0
      all_synced_with_main=0
      break
    fi
    main_ab="$(_ws_ahead_behind_origin_main "$repo")" || {
      all_have_origin_main=0
      all_synced_with_main=0
      break
    }
    ma="${main_ab[(w)1]}"
    mb="${main_ab[(w)2]}"
    if (( ma != 0 || mb != 0 )); then
      all_synced_with_main=0
    fi
  done

  if (( all_have_origin_main && all_synced_with_main )); then
    print -- "no changes to push"
    return 0
  fi

  local need_push_any=0
  for repo in "${repos[@]}"; do
    branch="$(_ws_current_branch "$repo")"
    dirty_state="$(_ws_dirty_status "$repo")"
    ab="$(_ws_ahead_behind "$repo")"
    ahead="${ab[(w)1]}"
    upstream="${ab[(w)3]}"

    if [[ "$branch" == "main" && "$dirty_state" == "clean" && "$ahead" -eq 0 ]]; then
      continue
    fi
    if (( ahead > 0 )); then
      need_push_any=1
      break
    fi
    if [[ "$upstream" == "none" ]]; then
      need_push_any=1
      break
    fi
  done

  if (( ! need_push_any )); then
    print -- "no changes to push"
    return 0
  fi

  {
    _ws_print_repo_list_header 1
    local push_rc
    for repo in "${repos[@]}"; do
      name="$(_ws_repo_name "$repo")"
      branch="$(_ws_current_branch "$repo")"
      dirty_state="$(_ws_dirty_status "$repo")"
      ab="$(_ws_ahead_behind "$repo")"
      ahead="${ab[(w)1]}"
      upstream="${ab[(w)3]}"

      if [[ "$branch" == "main" && "$dirty_state" == "clean" && "$ahead" -eq 0 ]]; then
        _ws_print_repo_status "$repo" '' 'no changes' 1
        continue
      fi

      if (( ahead == 0 )) && [[ "$upstream" != "none" ]]; then
        _ws_print_repo_status "$repo" '' 'no changes' 1
        continue
      fi

      if (( ${#opt_verbose[@]} )); then
        print -u2 -- "\n==> $name"
        if [[ "$upstream" == "none" ]]; then
          git -C "$repo" push -u origin HEAD
        else
          git -C "$repo" push
        fi
      else
        if [[ "$upstream" == "none" ]]; then
          git -C "$repo" push -u origin HEAD >/dev/null 2>&1
        else
          git -C "$repo" push >/dev/null 2>&1
        fi
      fi
      push_rc=$?

      if (( push_rc == 0 )); then
        _ws_print_repo_status "$repo" "$_ws_glyph_check_mark" ok 1
      else
        print -u2 -- "ws_push: git push failed in $name (exit $push_rc)"
        _ws_print_repo_status "$repo" "$_ws_glyph_ballot_x" failed 1
      fi
    done
  } | _ws_repo_table_columnize
}

ws_run() {
  emulate -L zsh
  setopt pipefail

  local -a opt_workspace opt_verbose opt_help opt_continue
  zparseopts -D -E \
    {w,-workspace}:=opt_workspace \
    {v,-verbose}=opt_verbose \
    {c,-continue}=opt_continue \
    {h,-help}=opt_help || return 2

  if (( ${#opt_help[@]} )); then
    cat <<'EOF'
Usage:
  ws_run [-w DIR] [-c] [-v] -- COMMAND [ARGS...]

Runs a generic command in every repo.

Example:
  ws_run -- git pull origin main

Options:
  -c, --continue        Continue running in later repos after a failure.
EOF
    _ws_usage_common_workspace
    return 0
  fi

  if (( $# == 0 )); then
    _ws_die "missing command. Example: ws_run -- git pull origin main"
    return 2
  fi

  local workspace
  workspace="$(_ws_workspace_root "${opt_workspace[-1]}")" || return 1

  local -a repos command
  repos=("${(@f)$(_ws_repo_dirs "$workspace")}")
  _ws_has_repos "${repos[@]}" || return 1

  command=("$@")

  local repo name rc overall_rc
  overall_rc=0

  for repo in "${repos[@]}"; do
    name="$(_ws_repo_name "$repo")"
    print -- "\n==> $name"

    (builtin cd "$repo" && "${command[@]}")
    rc=$?

    if (( rc != 0 )); then
      print -u2 -- "ws_run: command failed in $name with exit code $rc"
      overall_rc=$rc
      (( ${#opt_continue[@]} )) || return $rc
    fi
  done

  return $overall_rc
}

ws_branch() {
  emulate -L zsh
  setopt pipefail

  local -a opt_workspace opt_verbose opt_help opt_yes
  zparseopts -D -E \
    {w,-workspace}:=opt_workspace \
    {v,-verbose}=opt_verbose \
    {y,-yes}=opt_yes \
    {h,-help}=opt_help || return 2

  if (( ${#opt_help[@]} )); then
    cat <<'EOF'
Usage:
  ws_branch [-w DIR] [-y] [-v] BRANCH_NAME

Creates and checks out the same new branch in every repo.

Before changing anything, it:
  1. Checks that the branch does not already exist locally or on origin in any repo.
  2. Prints the current status for every repo (same table as ws_list; no trailing op column).
  3. Asks for confirmation unless -y/--yes is provided.

After creating each branch, it sets upstream to origin/BRANCH_NAME.

Options:
  -y, --yes             Skip confirmation prompt.
EOF
    _ws_usage_common_workspace
    return 0
  fi

  local branch_name="$1"
  if [[ -z "$branch_name" ]]; then
    _ws_die "missing branch name"
    return 2
  fi

  if [[ "$branch_name" == -* ]]; then
    _ws_die "branch name cannot start with '-'"
    return 2
  fi

  local workspace
  workspace="$(_ws_workspace_root "${opt_workspace[-1]}")" || return 1

  local -a repos conflicts dirty_repos
  repos=("${(@f)$(_ws_repo_dirs "$workspace")}")
  _ws_has_repos "${repos[@]}" || return 1

  local repo name dirty_state
  for repo in "${repos[@]}"; do
    name="$(_ws_repo_name "$repo")"

    if _ws_branch_exists "$repo" "$branch_name"; then
      conflicts+=("$name")
    fi

    dirty_state="$(_ws_dirty_status "$repo")"
    if [[ "$dirty_state" != "clean" ]]; then
      dirty_repos+=("$name:$dirty_state")
    fi
  done

  if (( ${#conflicts[@]} )); then
    print -u2 -- "Branch '$branch_name' already exists locally or on origin in:"
    printf '  - %s\n' "${conflicts[@]}" >&2
    return 1
  fi

  print -- "Current branches:"
  {
    _ws_print_repo_list_header
    for repo in "${repos[@]}"; do
      _ws_print_repo_status "$repo" '' '' 0
    done
  } | _ws_repo_table_columnize

  if (( ${#dirty_repos[@]} )); then
    print -- "\nRepos with uncommitted or unstaged changes:"
    printf '  - %s\n' "${dirty_repos[@]}"
  fi

  if (( ! ${#opt_yes[@]} )); then
    _ws_confirm "Create and check out '$branch_name' in ${#repos[@]} repos?" || {
      print -- "aborted"
      return 1
    }
  fi

  local rc overall_rc
  overall_rc=0

  for repo in "${repos[@]}"; do
    name="$(_ws_repo_name "$repo")"
    print -- "\n==> $name"

    git -C "$repo" checkout -b "$branch_name"
    rc=$?
    if (( rc != 0 )); then
      print -u2 -- "ws_branch: failed to create branch in $name"
      overall_rc=$rc
      continue
    fi

    # This sets tracking metadata even if the remote branch does not exist yet.
    # A later git push -u origin BRANCH_NAME will create it. This command may fail
    # when origin/BRANCH_NAME is absent, so fall back to config-based upstream setup.
    git -C "$repo" branch --set-upstream-to="origin/$branch_name" "$branch_name" >/dev/null 2>&1 \
      || {
        git -C "$repo" config "branch.$branch_name.remote" origin
        git -C "$repo" config "branch.$branch_name.merge" "refs/heads/$branch_name"
      }

    if (( ${#opt_verbose[@]} )); then
      git -C "$repo" status --short --branch
    fi
  done

  return $overall_rc
}

ws_create_workspace() {
  emulate -L zsh
  setopt pipefail

  local -a opt_base opt_verbose opt_help opt_remote_base opt_code
  zparseopts -D -E \
    {b,-base}:=opt_base \
    {r,-remote-base}:=opt_remote_base \
    {o,-open-code}=opt_code \
    {v,-verbose}=opt_verbose \
    {h,-help}=opt_help || return 2

  if (( ${#opt_help[@]} )); then
    cat <<'EOF'
Usage:
  ws_create_workspace [-b DIR] [-r URL_PREFIX] [-o] [-v] FOLDER_NAME REPO_NAME...

Creates a workspace folder and clones each repo into it.

Examples:
  ws_create_workspace my-workspace api web worker
  ws_create_workspace -r git@github.com:my-org/ my-workspace api web worker
  ws_create_workspace -r https://github.com/my-org/ my-workspace api web worker

Options:
  -b, --base DIR          Parent folder for the new workspace. Defaults to current directory.
  -r, --remote-base URL   Prefix used to build clone URLs from repo names.
                          If omitted, each repo argument is passed directly to git clone.
  -o, --open-code         Open the generated .code-workspace file in VS Code.
  -v, --verbose           Print extra details.
  -h, --help              Show help.
EOF
    return 0
  fi

  local folder_name="$1"
  shift || true

  if [[ -z "$folder_name" ]]; then
    _ws_die "missing folder name"
    return 2
  fi

  if (( $# == 0 )); then
    _ws_die "missing repo names"
    return 2
  fi

  local base_dir="${opt_base[-1]}"
  [[ -z "$base_dir" ]] && base_dir="$PWD"

  if [[ ! -d "$base_dir" ]]; then
    _ws_die "base directory does not exist: $base_dir"
    return 1
  fi

  local workspace_dir="$base_dir/$folder_name"
  if [[ -e "$workspace_dir" ]]; then
    _ws_die "workspace folder already exists: $workspace_dir"
    return 1
  fi

  mkdir -p "$workspace_dir" || return 1

  local remote_base="${opt_remote_base[-1]}"
  local -a repos
  repos=("$@")

  local repo clone_url repo_dir rc overall_rc
  overall_rc=0

  for repo in "${repos[@]}"; do
    repo_dir="$workspace_dir/$repo"

    if [[ -n "$remote_base" ]]; then
      clone_url="${remote_base}${repo}.git"
    else
      clone_url="$repo"
    fi

    print -- "\n==> cloning $repo"
    if (( ${#opt_verbose[@]} )); then
      git clone "$clone_url" "$repo_dir"
    else
      git clone "$clone_url" "$repo_dir" --quiet
    fi

    rc=$?
    if (( rc != 0 )); then
      print -u2 -- "ws_create_workspace: failed to clone $repo from $clone_url"
      overall_rc=$rc
    fi
  done

  local workspace_file="$workspace_dir/$folder_name.code-workspace"
  {
    print -- '{'
    print -- '  "folders": ['

    local i path comma
    for i in {1..${#repos[@]}}; do
      path="${repos[$i]}"
      comma="," 
      (( i == ${#repos[@]} )) && comma=""
      print -- "    { \"path\": \"$path\" }$comma"
    done

    print -- '  ],'
    print -- '  "settings": {}'
    print -- '}'
  } > "$workspace_file"

  print -- "\nCreated workspace: $workspace_dir"
  print -- "VS Code workspace file: $workspace_file"

  if (( ${#opt_code[@]} )); then
    command -v code >/dev/null 2>&1 && code "$workspace_file"
  fi

  return $overall_rc
}

# -----------------------------
# Optional aliases, commented out so humans cannot blame me for their shell habits.
# -----------------------------
# alias mwl='ws_list'
# alias mwf='ws_fetch'
# alias mwp='ws_pull'
# alias mwps='ws_push'
# alias mwr='ws_run'
# alias mwb='ws_branch'
