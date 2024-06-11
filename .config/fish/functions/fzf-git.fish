#!/opt/homebrew/bin/fish

# set __fzf_git "$HOME/.zprezto/.config/fish/functions/fzf-git.fish"
set __fzf_git "$HOME/.zprezto/fzf-git.sh"

function _fzf_git_check
    if git rev-parse HEAD > /dev/null 2>&1
    # if git rev-parse HEAD
        return 0
    else
        return 1
    end
end

# function _fzf_git_fzf
#     fzf-tmux -p80%,60% -- \
#         --layout=reverse --multi --height=50% --min-height=20 --border \
#         --border-label-pos=2 \
#         --color='header:italic:underline,label:blue' \
#         --preview-window='right,50%,border-left' \
#         --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' "$argv"
# end

function _fzf_git_branches
    _fzf_git_check || return
    bash "$__fzf_git" branches \
        | _fzf_git_fzf \
            --no-hscroll \
            --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) --' "$argv" \
        | sed 's/^..//' \
        | cut -d' ' -f1
end
# bash "$__fzf_git" branches \
#     | _fzf_git_fzf \
#         --ansi \
#         --border-label '🌲 Branches' \
#         --header-lines 2 \
#         --tiebreak begin \
#         --preview-window down,border-top,40% \
#         --color hl:underline,hl+:underline \
#         --no-hscroll \
#         --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
#         --bind "ctrl-o:execute-silent:bash $__fzf_git branch {}" \
#         --bind "alt-a:change-border-label(🌳 All branches)+reload:bash \"$__fzf_git\" all-branches" \
#         --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) --' "$argv" \
#     | sed 's/^..//' \
#     | cut -d' ' -f1
