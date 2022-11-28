#!/bin/bash

#This script will build and EKS cluster and create a MemoryDB cluster in it via ACK

set -x
set -e
#set -o history -o histexpand

exit_trap () {
  local lc="$BASH_COMMAND" rc=$?
  echo "Command [$lc] exited with code [$rc]"
}

trap exit_trap EXIT

export PATH=$PATH:.
export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
export CLUSTER_NAME=reinvent2022
export ACK_K8S_NAMESPACE=ack-system
# To decode encoded messages:
# aws sts decode-authorization-message --encoded-message <message>
# Create the cluster
aws_eks_create.sh

# Add clustom controllers for EC2 and MemoryDB to EKS
aws_ec2_crd.sh
aws_ec2_iam.sh

aws_memorydb_crd.sh
aws_memorydb_iam.sh

# Wait 30 seconds until all services are up.
sleep 30

# MemoryDB needs a security group and a subnet group
aws_memorydb_security_group.sh
aws_memorydb_subnet_group.sh
sleep 10

# Create MemoryDB service
aws_memorydb_create.sh

exit $?