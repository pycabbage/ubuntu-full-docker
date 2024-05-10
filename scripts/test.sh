#!/bin/bash --login --init-file ~/.bashrc

echo \$\-: \"$-\"

source $HOME/.bashrc

# initialize
# . "$HOME/.cargo/env"

# PYENV_ROOT="$HOME/.pyenv"
# PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"

# export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
# [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

NONROOT_USER=${NONROOT_USER:-"ubuntu"}

# test if user is $NONROOT_USER
CURRENT_USER=$(whoami)
echo current user: $CURRENT_USER
if [ $CURRENT_USER = $NONROOT_USER ]; then
  echo current user is specified non-root user
else
  sudo su $NONROOT_USER -c "[ \$(whoami) = $NONROOT_USER ] && echo current user can be promoted to $NONROOT_USER || ( echo current user cannot be promoted to $NONROOT_USER; exit 1 )"
fi

# test if LANG = ja_JP.UTF-8
echo LANG: $LANG
if [ $LANG = "ja_JP.UTF-8" ]; then
  echo current language is japanese
else
  echo current language is not japanese
  exit 1
fi

# test docker outside of docker
docker version

# test if `rustup`,`cargo`,`rustc` can be found in PATH
echo rustup: $(which rustup)
echo cargo:  $(which cargo)
echo rustc:  $(which rustc)

# test if `pyenv` and `python` is in PATH
echo pyenv:  $(which pyenv)
echo python: $(which python)
echo "Python version: $(python -V)"

# test nvm and node
echo "nvm: $(nvm --version)"
echo "node: $(node -v)"
