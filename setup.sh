#!/bin/zsh

set -x

# Check user dir
if [ "$(pwd)" != "$(echo ~$USER)/.zprezto" ]; then
    echo "You must download Steves repo in ~/.zprezto"
    exit 1
fi

chsh -s /bin/zsh

HOME=~$USER
ZPREZTO_HOME=${HOME}/.zprezto

# Link runcoms
rm -f ${HOME}/.zlogin
rm -f ${HOME}/.zlogout
rm -f ${HOME}/.zpreztorc
rm -f ${HOME}/.zprofile
rm -f ${HOME}/.zshenv
rm -f ${HOME}/.zshrc
ln -s ${ZPREZTO_HOME}/runcoms/zlogin ${HOME}/.zlogin
ln -s ${ZPREZTO_HOME}/runcoms/zlogout ${HOME}/.zlogout
ln -s ${ZPREZTO_HOME}/runcoms/zpreztorc ${HOME}/.zpreztorc
ln -s ${ZPREZTO_HOME}/runcoms/zprofile ${HOME}/.zprofile
ln -s ${ZPREZTO_HOME}/runcoms/zshenv ${HOME}/.zshenv
ln -s ${ZPREZTO_HOME}/runcoms/zshrc ${HOME}/.zshrc