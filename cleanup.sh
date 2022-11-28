#!/bin/bash

export PATH=$PATH:.
export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
export CLUSTER_NAME=reinvent2022
export ACK_K8S_NAMESPACE=ack-system

date > /tmp/delete.txt

kubectl delete cluster ${CLUSTER_NAME}
kubectl delete subnetgroup memorydb-${CLUSTER_NAME}-sg
kubectl delete securitygroup memorydb-${CLUSTER_NAME}

aws iam detach-role-policy --role-name ack-ec2-controller --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
aws iam delete-role --role-name ack-ec2-controller

aws iam detach-role-policy --role-name ack-memorydb-controller --policy-arn arn:aws:iam::aws:policy/AmazonMemoryDBFullAccess
aws iam delete-role --role-name ack-memorydb-controller

kubectl describe serviceaccount -n ack-system
kubectl get pods -n ack-system

helm uninstall -n ${ACK_K8S_NAMESPACE} ack-memorydb-controller
helm uninstall -n ${ACK_K8S_NAMESPACE} ack-ec2-controller

kubectl get pods -n ack-system
kubectl describe serviceaccount -n ack-system
kubectl delete namespaces ack-system

eksctl delete cluster -f eks_cluster.yaml
eksctl delete cluster --name ${CLUSTER_NAME} 

exit $?