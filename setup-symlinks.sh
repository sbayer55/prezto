#!/bin/zsh

ZPREZTO_HOME=${HOME}/.zprezto

function create-symlink () {
    source_path="${1}"
    target_path="${2}"

    rm "${target_path}"
    ln -s "${source_path}" "${target_path}"
}

create-symlink ${ZPREZTO_HOME}/runcoms/zlogin ${HOME}/.zlogin
create-symlink ${ZPREZTO_HOME}/runcoms/zlogout ${HOME}/.zlogout
create-symlink ${ZPREZTO_HOME}/runcoms/zpreztorc ${HOME}/.zpreztorc
create-symlink ${ZPREZTO_HOME}/runcoms/zprofile ${HOME}/.zprofile
create-symlink ${ZPREZTO_HOME}/runcoms/zshenv ${HOME}/.zshenv
create-symlink ${ZPREZTO_HOME}/runcoms/zshrc ${HOME}/.zshrc
create-symlink ${ZPREZTO_HOME}/.tmux.conf ${HOME}/.tmux.conf

mkdir $HOME/.config

# Make sure atuin is gone
rm -Rf $HOME/.config/atuin


for config_item in ${ZPREZTO_HOME}/.config/**
do
    ln -s $config_item $HOME/.config
done
