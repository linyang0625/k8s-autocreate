#@IgnoreInspection BashAddShebang
ssh-keygen -f "/var/jenkins_home/.ssh/known_hosts" -R ${K8S_MASTER_IP}
ssh -n -o StrictHostKeyChecking=no root@${K8S_MASTER_IP} 'rm -rf ~/k8s-autocreate && rm -f install.log && mkdir ~/k8s-autocreate'
ssh -n -o StrictHostKeyChecking=no root @${K8S_MASTER_IP} 'git clone https://github.com/xingangwang/k8s-autocreate.git /root/k8s-autocreate'
ssh -n -o StrictHostKeyChecking=no root@${K8S_MASTER_IP} 'sh /root/k8s-autocreate/script/install.sh ${registry_ip_port} ${K8S_MINIONS_IP} >> install.log '
#scp root@${K8S_MASTER_IP}:~/install.log install.log
#join_command=$( sed -n '/kubeadm join/p' install.log)
#echo $join_command

#minions=${MinionsIP}
#for i in ${minions} ; do
#	ssh-keygen -f "/var/jenkins_home/.ssh/known_hosts" -R ${i}
#	ssh -n -o StrictHostKeyChecking=no root@${i} 'rm -rf ~/k8s-autocreate && rm -f install.log && mkdir ~/k8s-autocreate'
#    scp -r * root@${i}:'~/k8s-autocreate'
#    ssh -n -o StrictHostKeyChecking=no root@${i} 'sh ~/k8s-autocreate/script/install_minion.sh ${registry_ip_port} >> install.log '
#    ssh -n -o StrictHostKeyChecking=no root@${i} ${join_command}
#done