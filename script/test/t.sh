#!/usr/bin/env bash
name=$(kubectl get node | awk 'NR==2{print $1}')
if [ $name = "master1" ];then
  echo "ok"
fi

ips="1 2 3"
array=("1 3 4")
for ip in ${array[@]}
do 
   echo $ip
done
