#!/usr/bin/env bash
#uname -a
#Linux ip-10-0-0-80 3.10.0-327.10.1.el7.x86_64 #1 SMP Tue Feb 16 17:03:50 UTC 2016 x86_64 x86_64 x86_64 GNU/Linux
#cat /etc/redhat-release
#CentOS Linux release 7.2.1511 (Core)
hostnamectl set-hostname master1

#cat <<EOF > /etc/yum.repos.d/kubernetes.repo
#[kubelet]
#name=kubelet
#baseurl=http://files.rm-rf.ca/rpms/kubelet/
#enabled=1
#gpgcheck=0
#EOF

#tee /etc/yum.repos.d/mritd.repo << EOF
#[mritd]
#name=Mritd Repository
#baseurl=https://yum.mritd.me/centos/7/x86_64
#enabled=1
#gpgcheck=1
#gpgkey=https://mritd.b0.upaiyun.com/keys/rpm.public.key
#EOF

yum update

yum -y install docker
systemctl enable docker && systemctl start docker
systemctl disable firewalld

#setenforce 0
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config

##Get rpm and install
#mkdir -p /var/k8s-autocreate
#cd /var/k8s-autocreate
#git clone https://github.com/xingangwang/k8s-rpm.git
yum install -y /root/k8s-autocreate/rpm/*.rpm
systemctl enable kubelet && systemctl start kubelet

##Yum install online
#yum install -y docker kubelet kubeadm kubectl kubernetes-cni ebtables

##Use accelerator of Aliyun docker hub
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://8vzilohj.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker

##Prepare images for initializing master
images=(kube-proxy-amd64:v1.5.5 kube-controller-manager-amd64:v1.5.5 kube-scheduler-amd64:v1.5.5 kube-apiserver-amd64:v1.5.5
 etcd-amd64:3.0.14-kubeadm kube-discovery-amd64:1.0 pause-amd64:3.0 kube-dnsmasq-amd64:1.4 exechealthz-amd64:1.2 kubedns-amd64:1.9 dnsmasq-metrics-amd64:1.0)
for imageName in ${images[@]} ; do
	docker pull ctagk8s/$imageName
	docker tag ctagk8s/$imageName gcr.io/google_containers/$imageName
	docker rmi ctagk8s/$imageName
done

#images=(kube-proxy-amd64:v1.5.5 kube-controller-manager-amd64:v1.5.5 kube-scheduler-amd64:v1.5.5 kube-apiserver-amd64:v1.5.5
# etcd-amd64:3.0.14-kubeadm kube-discovery-amd64:1.0 pause-amd64:3.0 kube-dnsmasq-amd64:1.4 exechealthz-amd64:1.2 kubedns-amd64:1.9 dnsmasq-metrics-amd64:1.0)
#for imageName in ${images[@]} ; do
#	docker pull registry.cn-hangzhou.aliyuncs.com/accenture_ctag/$imageName
#	docker tag registry.cn-hangzhou.aliyuncs.com/accenture_ctag/$imageName gcr.io/google_containers/$imageName
#	docker rmi registry.cn-hangzhou.aliyuncs.com/accenture_ctag/$imageName
#done

##Initialize master by kubeadm, TODO: Get join command text from output of below command
##--pod-network-cidr parameter is specified in flannel.yaml as next setp for installing pod network
kubeadm init --use-kubernetes-version v1.5.5 --pod-network-cidr 10.244.0.0/16

name=$(kubectl get node | awk 'NR==2{print $1}')
if [ $name = "master1" ];then
  echo "master initialize success!"
fi

##Installing a pod network
kubectl apply -f /root/k8s-autocreate/source/flannel.yaml
kubectl apply -f /root/k8s-autocreate/source/kubernetes-dashboard.yaml

#token=$(kubeadm init --use-kubernetes-version v1.5.5 --pod-network-cidr 10.244.0.0/16 | sed -n '$p') && ssh 192.168.247.131 $token
