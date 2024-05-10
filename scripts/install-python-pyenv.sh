#!/bin/bash -e

# "prepare" or "install" or "bashrc"
TASK=${1:-"prepare"}
PYTHON_VERSION=${2:-3.12.3}

if [ -d $HOME/.pyenv/bin ]; then
  echo "pyenv is already installed"
  source ~/.bashrc
  PYENV_ROOT="$HOME/.pyenv"
  PATH="$PYENV_ROOT/bin:$PATH"
  PYENV="$PYENV_ROOT/bin/pyenv"
  echo PATH: $PATH
  echo pyenv path: $(which pyenv)
  eval "$($PYENV init -)"
  eval "$($PYENV virtualenv-init -)"
fi

if [ $TASK = "prepare" ]; then
  # Install pyenv
  curl https://pyenv.run | bash

  # Add pyenv to bashrc
cat <<EOF >> ~/.bashrc
export PYENV_ROOT="\$HOME/.pyenv"
[[ -d \$PYENV_ROOT/bin ]] && export PATH="\$PYENV_ROOT/bin:\$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
EOF
  source ~/.bashrc
  PYENV_ROOT="$HOME/.pyenv"
  PYENV="$PYENV_ROOT/bin/pyenv"

  # Install pyenv-ccache
  git clone https://github.com/pyenv/pyenv-ccache.git $($PYENV root)/plugins/pyenv-ccache
else if [ $TASK = "bashrc" ]; then
cat <<EOF >> ~/.bashrc
export PYENV_ROOT="\$HOME/.pyenv"
[[ -d \$PYENV_ROOT/bin ]] && export PATH="\$PYENV_ROOT/bin:\$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
EOF
  source ~/.bashrc
else if [ $TASK = "install" ]; then
  PYENV_ROOT="$HOME/.pyenv"
  PYENV="$PYENV_ROOT/bin/pyenv"
  # Build python
  echo "Installing Python $PYTHON_VERSION"
  source ~/.bashrc
  $PYENV install -k -v $PYTHON_VERSION
  $PYENV global $PYTHON_VERSION
else
  echo "Invalid task: $TASK"
  exit 1
fi
