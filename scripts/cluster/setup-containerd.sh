#!/bin/bash

OS=linux
#ARCH=arm64
ARCH=amd64
CONTAINERD_VERSION=1.7.1
CONTAINERD_FILE=containerd-$CONTAINERD_VERSION-$OS-$ARCH.tar.gz 
RUNC_VERSION=1.1.12
RUNC_FILE=runc.amd64
PLUGINS_VERSION=1.4.1
PLUGINS_FILE=cni-plugins-$OS-$ARCH-v$PLUGINS_VERSION.tgz

TMP_DIR=$(mktemp -d)


cd $TMP_DIR

curl -L -o $CONTAINERD_FILE https://github.com/containerd/containerd/releases/download/v$CONTAINERD_VERSION/$CONTAINERD_FILE
sudo tar Cxzvf /usr/local $CONTAINERD_FILE

sudo mkdir -p /usr/local/lib/systemd/system
curl -L https://raw.githubusercontent.com/containerd/containerd/main/containerd.service | sudo tee /usr/local/lib/systemd/system/containerd.service  > /dev/null 

sudo systemctl daemon-reload
sudo systemctl enable --now containerd
 
curl -L -o $RUNC_FILE https://github.com/opencontainers/runc/releases/download/v$RUNC_VERSION/$RUNC_FILE
sudo install -m 755 $RUNC_FILE /usr/local/sbin/runc

curl -L -o $PLUGINS_FILE https://github.com/containernetworking/plugins/releases/download/v$PLUGINS_VERSION/$PLUGINS_FILE
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin $PLUGINS_FILE

sudo mkdir -p /etc/containerd
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml > /dev/null
sudo systemctl restart containerd
