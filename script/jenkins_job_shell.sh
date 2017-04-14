#@IgnoreInspection BashAddShebang
ssh-keygen -f "/var/jenkins_home/.ssh/known_hosts" -R ${K8S_MASTER_IP}
ssh -n -o StrictHostKeyChecking=no root@${K8S_MASTER_IP} 'rm -rf ~/k8s-autocreate && rm -f install.log'
ssh -n -o StrictHostKeyChecking=no root@${K8S_MASTER_IP} 'git clone https://github.com/xingangwang/k8s-autocreate.git /root/k8s-autocreate'
ssh -n -o StrictHostKeyChecking=no root@${K8S_MASTER_IP} "sh /root/k8s-autocreate/script/install.sh ${registry_ip_port} \"${K8S_MINIONS_IP}\" >> install.log"
