#!/bin/bash
BASE_PATH=/usr/local/src/Other

function fixSymlink() {
  cmd="ln -v -s ${1} ${2}"
  test -L ${2}
  if [[ $? == 0 ]]; then
    rm -fv ${2} && $cmd
  else
    printf "File ${2} is not a symlink!\n"
    ls -l ${2}
  fi
}

function createSymlink() {
  cmd="ln -v -s ${1} ${2}"
  test -L ${2}
  if [[ $? != 0 ]]; then
    rm -fv ${2} && $cmd
  else
    printf "Symlink ${2} is exist!\n"
    ls -l ${2}
  fi
}

fixSymlink ${BASE_PATH}/bash/.bashrc ~/.bashrc
fixSymlink ${BASE_PATH}/bash/bashrc_mc ~/.local/share/mc/bashrc
