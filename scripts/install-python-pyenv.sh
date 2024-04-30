#!/bin/bash -e

# "prepare" or "install" or "bashrc"
TASK=${1:-"prepare"}
PYTHON_VERSION=${2:-3.12.3}

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

  # Install pyenv-ccache
  git clone https://github.com/pyenv/pyenv-ccache.git $(pyenv root)/plugins/pyenv-ccache
else if [ $TASK = "bashrc" ]; then
cat <<EOF >> ~/.bashrc
export PYENV_ROOT="\$HOME/.pyenv"
[[ -d \$PYENV_ROOT/bin ]] && export PATH="\$PYENV_ROOT/bin:\$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
EOF
  source ~/.bashrc
else if [ $TASK = "install" ]; then
  # Build python
  echo "Installing Python $PYTHON_VERSION"
  source ~/.bashrc
  pyenv install -k -v $PYTHON_VERSION
  pyenv global $PYTHON_VERSION
else
  echo "Invalid task: $TASK"
  exit 1
fi



