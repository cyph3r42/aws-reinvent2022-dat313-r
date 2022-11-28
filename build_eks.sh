#!/bin/bash

# This cript will build and EKS cluster in AWS to be used for lab purposes
set -x

export PATH=$PATH:.
export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
export CLUSTER_NAME=reinvent2022
export ACK_K8S_NAMESPACE=ack-system

# Create the EKS cluster
aws_eks_create.sh
exit 0