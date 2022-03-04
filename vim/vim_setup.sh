#!/bin/zsh

HOME=~$USER
ZPREZTO_HOME=${HOME}/.zprezto

echo "Removing existing ~/.vim"

rm -rf "${HOME}/.vim" "${HOME}/vim"
rm -f "${HOME}/.vim*"

echo "Linking ${ZPREZTO_HOME}/vim/.vimrc"

git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
ln -s ${ZPREZTO_HOME}/vim/.vimrc ${HOME}/.vimrc
vim +PluginInstall +qall
