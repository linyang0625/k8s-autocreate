#@IgnoreInspection BashAddShebang
ssh-keygen -f "/var/jenkins_home/.ssh/known_hosts" -R ${MasterIP}
ssh -n -o StrictHostKeyChecking=no root@${MasterIP} 'rm -rf ~/k8s-autocreate && rm -f install.log && mkdir ~/k8s-autocreate'
scp -r * root@${MasterIP}:'~/k8s-autocreate'
ssh -n -o StrictHostKeyChecking=no root@${MasterIP} 'sh ~/k8s-autocreate/script/install.sh >> install.log'
scp root@${MasterIP}:~/install.log install.log
join_command=$(tail -7 install.log | sed -n 1p)
echo $join_command

minions=${MinionsIP}
for i in ${minions} ; do
	ssh-keygen -f "/var/jenkins_home/.ssh/known_hosts" -R ${i}
	ssh -n -o StrictHostKeyChecking=no root@${i} 'rm -rf ~/k8s-autocreate && rm -f install.log && mkdir ~/k8s-autocreate'
    scp -r * root@${i}:'~/k8s-autocreate'
    ssh -n -o StrictHostKeyChecking=no root@${i} 'sh ~/k8s-autocreate/script/install_minion.sh >> install.log'
    ssh -n -o StrictHostKeyChecking=no root@${i} ${join_command}
done