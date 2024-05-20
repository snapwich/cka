#!/usr/bin/env bash

if ! git remote | grep -q kubespray; then
  git remote add kubespray git@github.com:kubernetes-sigs/kubespray.git
fi
git fetch kubespray master
git subtree pull --prefix kubespray kubespray master --squash