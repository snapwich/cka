#!/bin/bash

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint k8s-cp.internal
