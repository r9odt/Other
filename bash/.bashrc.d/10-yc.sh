#!bin/bash

if [[ ! ${PATH} =~ "${HOME}/.local/opt/yandex-cli" ]]; then
  if [ -d ${HOME}/.local/opt/yandex-cli ]; then
    export PATH="${HOME}/.local/opt/yandex-cli/bin:${PATH}"
  fi
fi
