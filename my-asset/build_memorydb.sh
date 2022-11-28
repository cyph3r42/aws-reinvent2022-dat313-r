#!/bin/bash

# This script will build a MemoryDB cluster on EKS for lab purposes.
# Dependencies EKS cluster (build_eks.sh)
set -x

export PATH=$PATH:.
export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
export CLUSTER_NAME=reinvent2022
export ACK_K8S_NAMESPACE=ack-system

while [ $(aws eks describe-cluster --name $CLUSTER_NAME --query 'cluster.status') != "\"ACTIVE\"" ]
do
  echo "waiting for EKS completion sleep 10..."
  sleep 10
done

echo "EKS cluster is in ACTIVE mode"
echo "At this point an EKS cluster with the name $CLUSTER_NAME is assumed to exists"
echo "But eksctl has a second CF stack to execute wait for the completion of the second stack"

count=0
while ! $(aws --region ${AWS_REGION} cloudformation wait stack-exists --stack-name "eksctl-${CLUSTER_NAME}-nodegroup-eks-node-group"); [ $count -ne 15 ]; 
do 
  echo "waiting for eksctl-${CLUSTER_NAME}-nodegroup-eks-node-group template to appear"
  ((count=count+1)) 
done

count=0
while ! $(aws --region ${AWS_REGION} cloudformation wait stack-create-complete --stack-name "eksctl-${CLUSTER_NAME}-nodegroup-eks-node-group"); [ $count -ne 15 ]; 
do 
  echo "waiting for eksctl-${CLUSTER_NAME}-nodegroup-eks-node-group template to complete"
  ((count=count+1)) 
done

# Add clustom controllers for EC2 and MemoryDB to EKS
aws_ec2_crd.sh
aws_ec2_iam.sh

aws_memorydb_crd.sh
aws_memorydb_iam.sh
sleep 30

# MemoryDB needs a security group and subnet
aws_memorydb_security_group.sh
aws_memorydb_subnet_group.sh
sleep 10

# Create MemoryDB service
aws_memorydb_create.sh

exit 0