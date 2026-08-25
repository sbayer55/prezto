#!/bin/zsh

ZPREZTO_HOME=${HOME}/.zprezto

# Timestamp shared by every backup this run makes.
BACKUP_SUFFIX="backup.$(date +%Y%m%d%H%M%S)"

# Replace target_path with a symlink to source_path.
#
# Anything already there that is not one of our symlinks is moved aside rather
# than deleted: `rm -RI` used to prompt for each one, and a piped or empty
# stdin answers "no", which silently left the config unlinked.
function create-symlink () {
    local source_path="${1}"
    local target_path="${2}"

    # Skip sources that are not in the repo, otherwise we leave a dangling
    # symlink behind (e.g. ~/.tmux.conf when no .tmux.conf is checked in).
    if [[ ! -e "${source_path}" ]]; then
        echo "skipping ${target_path}: ${source_path} does not exist"
        return 0
    fi

    if [[ -L "${target_path}" ]]; then
        # Already ours (or someone else's link) - just repoint it.
        rm -f "${target_path}"
    elif [[ -e "${target_path}" ]]; then
        local backup_path="${target_path}.${BACKUP_SUFFIX}"
        echo "backing up existing ${target_path} -> ${backup_path}"
        if ! mv "${target_path}" "${backup_path}"; then
            echo "failed to back up ${target_path}; leaving it alone" >&2
            return 1
        fi
    fi

    if ln -s "${source_path}" "${target_path}"; then
        echo "linked ${target_path} -> ${source_path}"
    else
        echo "failed to link ${target_path} -> ${source_path}" >&2
        return 1
    fi
}

failures=0

create-symlink ${ZPREZTO_HOME}/runcoms/bash_profile ${HOME}/.bash_profile || ((failures++))
create-symlink ${ZPREZTO_HOME}/runcoms/bashrc ${HOME}/.bashrc || ((failures++))
create-symlink ${ZPREZTO_HOME}/runcoms/profile ${HOME}/.profile || ((failures++))
create-symlink ${ZPREZTO_HOME}/runcoms/zlogin ${HOME}/.zlogin || ((failures++))
create-symlink ${ZPREZTO_HOME}/runcoms/zlogout ${HOME}/.zlogout || ((failures++))
create-symlink ${ZPREZTO_HOME}/runcoms/zprofile ${HOME}/.zprofile || ((failures++))
create-symlink ${ZPREZTO_HOME}/runcoms/zshenv ${HOME}/.zshenv || ((failures++))
create-symlink ${ZPREZTO_HOME}/runcoms/zshrc ${HOME}/.zshrc || ((failures++))
create-symlink ${ZPREZTO_HOME}/.tmux.conf ${HOME}/.tmux.conf || ((failures++))
create-symlink ${ZPREZTO_HOME}/.tmux.conf.local ${HOME}/.tmux.conf.local || ((failures++))
create-symlink ${ZPREZTO_HOME}/.tmux ${HOME}/.tmux || ((failures++))

mkdir -p ${HOME}/.config

# Make sure atuin is gone
rm -Rf ${HOME}/.config/atuin

for config_item in ${ZPREZTO_HOME}/.config/*(N); do
    create-symlink "${config_item}" "${HOME}/.config/$(basename "${config_item}")" || ((failures++))
done

if (( failures > 0 )); then
    echo "Symlink setup finished with ${failures} failure(s)" >&2
    exit 1
fi

echo "Symlink setup complete"
