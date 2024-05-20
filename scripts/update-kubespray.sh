#!/usr/bin/env bash

git remote add kubespray git@github.com:kubernetes-sigs/kubespray.git
git fetch kubespray master
git subtree pull --prefix ./kubespray kubespray master --squash