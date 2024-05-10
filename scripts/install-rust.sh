#!/bin/bash -e

TASK=${1:-"empty"}

if [ $TASK = "install" ]; then
  echo installing rustup and toolchain
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
elif [ $TASK = "bashrc" ]; then
  echo "write script to .bashrc"
  echo ". \"\$HOME/.cargo/env\"" >> $HOME/.bashrc
else
  echo "unknown task: $TASK"
fi
