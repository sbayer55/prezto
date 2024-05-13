#!/opt/homebrew/bin/fish

fish_add_path -p "/opt/homebrew/bin"
fish_add_path -p "/usr/local/opt/curl/bin"
fish_add_path -p "$HOME/code/bin/commands"
fish_add_path -p "$HOME/code/bin/tools"
fish_add_path -p "$HOME/code/bin"
fish_add_path -p "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
fish_add_path -p "$HOME/.local/bin"

fish_add_path "$HOME/.toolbox/bin"
fish_add_path "$HOME/.rvm/bin"

# test -e if file exists
# test -d if directory exists

if test -d "/opt/homebrew/opt/python@3.12/bin/python3"
    fish_add_path -p "/opt/homebrew/opt/python@3.12/bin"
    alias python3="/opt/homebrew/opt/python@3.12/bin/python"
else if test -d "/opt/python3/bin/python3"
    fish_add_path -p "/opt/python3/bin"
    alias "python3"="/opt/python3/bin/python3"
    alias "python"="/opt/python3/bin/python3"
end

# Not valid fish syntax
# if test -e "$HOME/.zprezto/runcoms/amazonrc"
#     source "$HOME/.zprezto/runcoms/amazonrc"
# end

# Java 21
if test -e "$HOME/.jdks/corretto-21.0.2/bin/java"
    set JAVA_HOME="$HOME/.jdks/corretto-21.0.2/bin"
    fish_add_path -p "$HOME/.jdks/corretto-21.0.2/bin"
end

# Maven
if test -e "/home/smbayer/apache-maven-3.9.6/bin/mvn"
    fish_add_path -p "/home/smbayer/apache-maven-3.9.6/bin:$PATH"
end

# Ruby 2.7
if test -e "/usr/local/opt/ruby@2.7/bin"
    fish_add_path -p "/usr/local/opt/ruby@2.7/bin"
end

if status is-interactive
    fish_add_path -p "/opt/homebrew/Cellar/ruby/3.3.0/bin"


    # --- setup fzf theme ---
    set --local fg "#CBE0F0"
    set --local bg "#011628"
    set --local bg_highlight "#143652"
    set --local purple "#B388FF"
    set --local blue "#06BCE4"
    set --local cyan "#2CF9ED"

    # set --export FZF_DEFAULT_OPTS "--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"
    set --export FZF_DEFAULT_COMMAND "fd --hidden --strip-cwd-prefix --exclude .git"
    set --export FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
    set --export FZF_ALT_C_COMMAND "fd --type=d --hidden --strip-cwd-prefix --exclude .git"

    function _fzf_compgen_path
        fd --hidden --exclude .git . "$1"
    end

    function _fzf_compgen_dir
        fd --type=d --hidden --exclude .git . "$1"
    end

    set --export FZF_CTRL_T_OPTS "--preview 'bat -n --color=always --line-range :500 {}'"
    set --export FZF_ALT_C_OPTS "--preview 'eza --tree --color=always {} | head -200'"


    function _fzf_comprun
        set --local command $1
        shift

        switch "$command"
            case "cd"
                fzf --preview 'eza --tree --color=always {} | head -200'
            case "export"
                fzf --preview "eval 'echo \$'{}"
            case "unset"
                fzf --preview "eval 'echo \$'{}"
            case "ssh"
                fzf --preview 'dig {}'
            case "*"
                fzf --preview "bat -n --color=always --line-range :500 {}"
        end
    end

    # source "${HOME}/.zprezto/fzf-git.sh"
    
    # ----- Bat (better cat) -----

    set --export BAT_THEME tokyonight_moon
    alias bat="bat --paging=never"
    alias cat="bat --paging=never"

    # ---- Eza (better ls) -----

    alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"

    starship init fish | source
    zoxide init --cmd 'cd' fish | source
    atuin init fish | source

    source ~/.iterm2_shell_integration.fish
end
