#!/bin/bash

# kubectl drain <node-to-drain> --ignore-daemonsets

sudo apt-mark unhold kubeadm kubelet kubectl
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-mark hold kubeadm kubelet kubectl

sudo systemctl daemon-reload
sudo systemctl restart kubelet

# kubectl uncordon <node-to-uncordon>