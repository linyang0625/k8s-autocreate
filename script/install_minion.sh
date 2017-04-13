#!/bin/bash
#hostnamectl set-hostname minion1

#yum -y install git

##Get rpm and install
#git clone https://github.com/xingangwang/k8s-rpm.git
yum -y install docker
systemctl enable docker && systemctl start docker
systemctl disable firewalld

setenforce 0
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config

basepath=$(cd 'dirname $0'/..; pwd)
yum install -y $basepath/rpm/*.rpm
#yum install -y docker kubelet kubeadm kubectl kubernetes-cni ebtables
systemctl enable kubelet && systemctl start kubelet

##Use accelerator of Aliyun docker hub
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["https://8vzilohj.mirror.aliyuncs.com"],
   "insecure-registries":["$1"]
}
EOF
systemctl daemon-reload
systemctl restart docker

export KUBE_REPO_PREFIX=ctagk8s
$2
#images=(pause-amd64:3.0 kube-proxy-amd64:v1.5.5  kube-dnsmasq-amd64:1.4 exechealthz-amd64:1.2
# kubedns-amd64:1.9 dnsmasq-metrics-amd64:1.0)
#for imageName in ${images[@]} ; do
#  docker pull registry.cn-hangzhou.aliyuncs.com/accenture_ctag/$imageName
#  docker tag registry.cn-hangzhou.aliyuncs.com/accenture_ctag/$imageName gcr.io/google_containers/$imageName
#  docker rmi registry.cn-hangzhou.aliyuncs.com/accenture_ctag/$imageName
#done
#images=(pause-amd64:3.0 kube-proxy-amd64:v1.5.5  kube-dnsmasq-amd64:1.4 exechealthz-amd64:1.2
# kubedns-amd64:1.9 dnsmasq-metrics-amd64:1.0)
#for imageName in ${images[@]} ; do
#  docker pull ctagk8s/$imageName
#  docker tag ctagk8s/$imageName gcr.io/google_containers/$imageName
#  docker rmi ctagk8s/$imageName
#done


