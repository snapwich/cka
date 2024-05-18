#!/bin/bash

SYSCTL_CONF="/etc/sysctl.d/99-ipforward.conf"

sudo tee $SYSCTL_CONF <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sudo sysctl --system

# for debian bookworm
sudo modprobe overlay
sudo modprobe br_netfilter
echo -e overlay\\nbr_netfilter | sudo tee /etc/modules-load.d/k8s.conf > /dev/null