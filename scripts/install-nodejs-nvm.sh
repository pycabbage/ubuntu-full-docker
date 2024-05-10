#!/bin/bash -e

TASK=${1:-"empty"}

if [ $TASK = "install" ]; then
  NODEJS_VERSION=${2:-$NODEJS_VERSION}
  NVM_VERSION=${NVM_VERSION:-"v0.39.7"}
  echo "install nvm and nodejs $NODEJS_VERSION"

  # install nvm
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash

  # load nvm
  export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

elif [ $TASK = "bashrc" ]; then
  echo "write script to .bashrc"
  echo export NVM_DIR=\"\$\([ -z \"\${XDG_CONFIG_HOME-}\" ] \&\& printf %s \"\${HOME}/.nvm\" \|\| printf %s \"\${XDG_CONFIG_HOME}/nvm\"\)\" >> $HOME/.bashrc
  echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"" >> $HOME/.bashrc
else
  echo "unknown task: $TASK"
fi
