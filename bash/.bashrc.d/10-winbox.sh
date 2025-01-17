#!bin/bash

WINBOX_PATH=${HOME}/.local/opt/winbox
if [[ ! ${PATH} =~ "${WINBOX_PATH}" ]]; then
export PATH="${WINBOX_PATH}:${PATH}"
fi
