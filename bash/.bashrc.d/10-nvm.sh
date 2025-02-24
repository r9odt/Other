#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
if [ -d "${HOME}/.yarn/bin" ]; then
  YARN_PATH="${HOME}/.yarn/bin"
  if [[ ! ${PATH} =~ "${YARN_PATH}" ]]; then
    export PATH="${YARN_PATH}:${PATH}"
  fi
fi
