#!/bin/sh

set -x

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

read -r -d '' CLUSTER_MANIFEST <<EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ${CLUSTER_NAME} 
  region: ${AWS_REGION} 
  version: "1.24"

vpc:
  cidr: 172.31.0.0/16

nodeGroups:
  - name: eks-node-group
    instanceType: m4.large
    minsize: 1
    maxsize: 3
    desiredCapacity: 2
    privateNetworking: true
EOF

echo "${CLUSTER_MANIFEST}" > eks_cluster.yaml

eksctl create cluster -f eks_cluster.yaml
if [ $? -ne 0 ]
then
  exit 1
fi

eksctl create iamidentitymapping --cluster ${CLUSTER_NAME} --arn  arn:aws:iam::${AWS_ACCOUNT_ID}:role/WSParticipantRole --group system:masters --username admin
# Cloud9 role
# eksctl create iamidentitymapping --cluster ${CLUSTER_NAME} --arn  arn:aws:iam::${AWS_ACCOUNT_ID}:assumed-role/* --group system:masters --username admin

exit $?
