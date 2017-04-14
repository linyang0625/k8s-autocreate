#!/bin/bash

registry_ip_port=$1
join_command=$2
self_private_ip=$3
hostname="minion-"$self_private_ip

#set hostname for node
hostnamectl --static set-hostname $hostname

cloud_cfg_file=/etc/cloud/cloud.cfg
if [ -f "$cloud_cfg_file" ]; then
  sed -i '$a\preserve_hostname: true' $cloud_cfg_file
fi

##Get rpm and install
yum -y install docker
systemctl enable docker && systemctl start docker
systemctl disable firewalld

setenforce 0
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config

sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=1
sed -i '$a\net.bridge.bridge-nf-call-iptables=1' /etc/sysctl.conf
sed -i '$a\net.bridge.bridge-nf-call-ip6tables=1' /etc/sysctl.conf

basepath=$(cd `dirname $0`/..; pwd)
yum install -y $basepath/rpm/*.rpm
systemctl enable kubelet && systemctl start kubelet

##Use accelerator of Aliyun docker hub and insecure registry
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["https://8vzilohj.mirror.aliyuncs.com"],
   "insecure-registries":["$registry_ip_port"]
}
EOF
systemctl daemon-reload
systemctl restart docker

export KUBE_REPO_PREFIX=ctagk8s
$join_command



