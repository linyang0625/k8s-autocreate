#!/usr/bin/env bash
#uname -a
#Linux ip-10-0-0-80 3.10.0-327.10.1.el7.x86_64 #1 SMP Tue Feb 16 17:03:50 UTC 2016 x86_64 x86_64 x86_64 GNU/Linux
#cat /etc/redhat-release
#CentOS Linux release 7.2.1511 (Core)
#hostnamectl --static set-hostname master

registry_ip_port=$1
minionsIP=$2
masterIP=$3
#hostname="master"

#set hostname for node
hostnamectl --static --transient set-hostname $hostname

cloud_cfg_file=/etc/cloud/cloud.cfg
if [ -f "$cloud_cfg_file" ]; then
  sed -i '$a\preserve_hostname: true' $cloud_cfg_file
fi

yum update

yum -y install docker
systemctl enable docker && systemctl start docker
systemctl disable firewalld

setenforce 0
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config

sysctl -w net.bridge.bridge-nf-call-iptables=1
sysctl -w net.bridge.bridge-nf-call-ip6tables=1
sed -i '$a\net.bridge.bridge-nf-call-iptables=1' /etc/sysctl.conf
sed -i '$a\net.bridge.bridge-nf-call-ip6tables=1' /etc/sysctl.conf



##Get rpm and install
#mkdir -p /var/k8s-autocreate
#cd /var/k8s-autocreate

basepath=$(cd `dirname $0`/..; pwd)
yum install -y $basepath/rpm/*.rpm
systemctl enable kubelet && systemctl start kubelet

##Yum install online
#yum install -y docker kubelet kubeadm kubectl kubernetes-cni ebtables

##Use accelerator of Aliyun docker hub
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["https://8vzilohj.mirror.aliyuncs.com"],
   "insecure-registries":["$registry_ip_port"]
}
EOF
systemctl daemon-reload
systemctl restart docker

##Prepare images for initializing master
#images=(kube-proxy-amd64:v1.5.5 kube-controller-manager-amd64:v1.5.5 kube-scheduler-amd64:v1.5.5 kube-apiserver-amd64:v1.5.5
# etcd-amd64:3.0.14-kubeadm kube-discovery-amd64:1.0 pause-amd64:3.0 kube-dnsmasq-amd64:1.4 exechealthz-amd64:1.2 kubedns-amd64:1.9 dnsmasq-metrics-amd64:1.0)
#for imageName in ${images[@]} ; do
#	docker pull ctagk8s/$imageName
#	docker tag ctagk8s/$imageName gcr.io/google_containers/$imageName
#	docker rmi ctagk8s/$imageName
#done

#images=(kube-proxy-amd64:v1.5.5 kube-controller-manager-amd64:v1.5.5 kube-scheduler-amd64:v1.5.5 kube-apiserver-amd64:v1.5.5
# etcd-amd64:3.0.14-kubeadm kube-discovery-amd64:1.0 pause-amd64:3.0 kube-dnsmasq-amd64:1.4 exechealthz-amd64:1.2 kubedns-amd64:1.9 dnsmasq-metrics-amd64:1.0)
#for imageName in ${images[@]} ; do
#	docker pull registry.cn-hangzhou.aliyuncs.com/accenture_ctag/$imageName
#	docker tag registry.cn-hangzhou.aliyuncs.com/accenture_ctag/$imageName gcr.io/google_containers/$imageName
#	docker rmi registry.cn-hangzhou.aliyuncs.com/accenture_ctag/$imageName
#done

export KUBE_REPO_PREFIX=ctagk8s

##Initialize master by kubeadm, TODO: Get join command text from output of below command
##--pod-network-cidr parameter is specified in flannel.yaml as next setp for installing pod network
kubeadm init --use-kubernetes-version v1.5.5 --pod-network-cidr 10.244.0.0/16 --skip-preflight-checks
#--api-advertise-addresses $masterIP

sed -i '/--insecure-bind-address/s/127.0.0.1/0.0.0.0/' /etc/kubernetes/manifests/kube-apiserver.json
sed -i '$a\--runtime-config=batch/v2alpha1' /etc/kubernetes/manifests/kube-apiserver.json
sleep 5

name=$(kubectl get node | awk 'NR==2{print $1}')
if [ $name = "master1" ];then
  echo "master initialize success!"
fi

##Installing a pod network
kubectl apply -f /root/k8s-autocreate/source/flannel.yaml
kubectl apply -f /root/k8s-autocreate/source/kubernetes-dashboard.yaml

#token=$(kubeadm init --use-kubernetes-version v1.5.5 --pod-network-cidr 10.244.0.0/16 | sed -n '$p') && ssh 192.168.247.131 $token

join_command=$( sed -n '/kubeadm join --skip-preflight-checks/p' install.log)

for minion in ${minionsIP[@]} ; do
    ssh -o StrictHostKeyChecking=no -i /root/jenkins_sshkey/id_rsa root@${minion} "rm -rf $basepath && rm -f install.log && mkdir $basepath"
    scp -r -i /root/jenkins_sshkey/id_rsa $basepath root@$minion:$basepath/..
    ssh -i /root/jenkins_sshkey/id_rsa root@$minion "sh $basepath/script/install_minion.sh $1 \"$join_command\" $minion >> install.log"
done
