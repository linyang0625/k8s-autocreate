#!/usr/bin/env bash

##Resolve DNS issue
printf '[Service]\nEnvironment="KUBELET_DNS_ARGS=--cluster-domain=cluster.local --cluster-dns=%s"\n' 10.0.0.10 > /etc/systemd/system/kubelet.service.d/20-dns-override.conf
systemctl daemon-reload
systemctl restart kubelet.service

kubectl delete svc kube-dns -n kube-system
kubectl apply -f kubedns-svc.yaml -n kube-system