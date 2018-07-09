#!/bin/bash
CONFIG=$1
ROOT_HOSTNAME=$2
ROOT_IP=$3
NODE_HOSTNAME=$4
NODE_IP=$5

kubeadm alpha phase certs all --config $CONFIG
kubeadm alpha phase kubelet config write-to-disk --config $CONFIG
kubeadm alpha phase kubelet write-env-file --config $CONFIG
kubeadm alpha phase kubeconfig kubelet --config $CONFIG
kubectl exec -n kube-system etcd-$ROOT_HOSTNAME -- etcdctl --ca-file /etc/kubernetes/pki/etcd/ca.crt --cert-file /etc/kubernetes/pki/etcd/peer.crt --key-file /etc/kubernetes/pki/etcd/peer.key --endpoints=https://$ROOT_IP:2379 member add $NODE_HOSTNAME https://$NODE_IP:2380
kubeadm alpha phase etcd local --config $CONFIG
kubeadm alpha phase kubeconfig all --config /etc/kubernetes/kubeadm-config-second.ym
kubeadm alpha phase controlplane all --config $CONFIG
kubeadm alpha phase mark-master --config $CONFIG
