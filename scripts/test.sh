#!/bin/bash -e

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
docker run -it --rm hello-world

# test if `rustup`,`cargo`,`rustc` can be found in PATH
echo rustup: $(which rustup)
echo cargo:  $(which cargo)
echo rustc:  $(which rustc)

# test if `pyenv` and `python` is in PATH
echo pyenv: $(which pyenv)
echo python:  $(which python)
echo Python version: $(python -V)
