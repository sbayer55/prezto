#!/bin/zsh

HOME=~$USER
ZPREZTO_HOME=${HOME}/.zprezto

echo "Install prerequisite"
sudo apt install -y libncurses5-dev libgnome2-dev libgnomeui-dev \
    libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
    libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
    python3-dev ruby-dev lua5.1 lua5.1-dev libperl-dev git \
    checkinstall

echo "Removing existing vim install"
sudo apt remove -y vim vim-runtime gvim vim-tiny vim-common \
    vim-gui-common vim-nox

rm -rf "${HOME}/.vim"
rm -f "${HOME}/.vim*"

cd ${HOME}

echo "Downloading Vim source" 
git clone https://github.com/vim/vim.git

cd vim

echo "Comfigure Vim"
./configure --with-features=huge \
            --enable-multibyte \
            --enable-rubyinterp=yes \
            --enable-pythoninterp=yes \
            # --with-python-config-dir=/usr/lib/python2.7/config \
            /usr/lib/python2.7/config-x86_64-linux-gnu \
            --enable-python3interp=yes \
            # --with-python3-config-dir=/usr/lib/python3.5/config \
            --with-python3-config-dir=/usr/lib/python3.6/config-3.6m-x86_64-linux-gnu \
            --enable-perlinterp=yes \
            --enable-luainterp=yes \
            --enable-gui=gtk2 \
            --enable-cscope \
            --prefix=/usr/local

echo "Make Vim"
make VIMRUNTIMEDIR=/usr/local/share/vim/vim80
sudo checkinstall

sudo update-alternatives --install /usr/bin/editor editor /usr/bin/vim 1
sudo update-alternatives --set editor /usr/bin/vim
sudo update-alternatives --install /usr/bin/vi vi /usr/bin/vim 1
sudo update-alternatives --set vi /usr/bin/vim

git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
ln -s ${ZPREZTO_HOME}/vim/.vimrc ${HOME}/.vimrc
vim +PluginInstall +qall

echo "Compile YouCompleteMe"
cd ${HOME}/.vim/bundle/YouCompleteMe
./install.py --clang-completer
