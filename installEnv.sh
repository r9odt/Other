#!/bin/bash
cp -vf bash/.bashrc ~/.bashrc
cp -vf bash/.bash_profile ~/.bash_profile
cp -vf bash/.profile ~/.profile
cp -vf terraform/.terraformrc ~/.terraformrc
mkdir -vp ~/.githooks
cp -vf git/hooks/* ~/.githooks/
cp -vf tmux/.tmux.conf ~/.tmux.conf
mkdir -vp ~/.bashrc.d
cp -vf bash/.bashrc.d/*.sh ~/.bashrc.d
./git/gitalias.sh
chmod -v 700 ~
mkdir -vp ~/.local/{bin,opt,src,etc}
# deprecated
rm -fv ~/.bashrc.d/{ansible,autoenv,aws,go,nvm}.sh
