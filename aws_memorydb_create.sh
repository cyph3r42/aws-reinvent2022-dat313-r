#!/bin/sh

set -x 

sleep 20

EKS_VPC_ID=$(aws --region ${AWS_REGION} eks describe-cluster --name $CLUSTER_NAME --query cluster.resourcesVpcConfig.vpcId)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
#CLUSTER_NAME=cluster-$AWS_ACCOUNT_ID

MEMORYDB_SECURITY_GROUP_NAME="memorydb-${CLUSTER_NAME}"
MEMORYDB_SECURITY_GROUP_ID=$(aws --region ${AWS_REGION} ec2 describe-security-groups \
	--filters "Name=vpc-id,Values=$EKS_VPC_ID" "Name=group-name,Values=$MEMORYDB_SECURITY_GROUP_NAME" \
	--query 'SecurityGroups[*].GroupId' --output text)
MEMORYDB_SUBNET_GROUP="memorydb-$CLUSTER_NAME-sg"

read -r -d '' CLUSTER_MANIFEST <<EOF
apiVersion: memorydb.services.k8s.aws/v1alpha1
kind: Cluster

metadata:
  name: ${CLUSTER_NAME} 

spec:
  aclName: open-access
  autoMinorVersionUpgrade: true
  description: "test cluster created by ACK"
  engineVersion: '6.2'
  name: ${CLUSTER_NAME} 
  nodeType: 'db.t4g.small'
  numReplicasPerShard: 1
  numShards: 1
  parameterGroupName: default.memorydb-redis6
  securityGroupIDs:
  - ${MEMORYDB_SECURITY_GROUP_ID}
  subnetGroupName: ${MEMORYDB_SUBNET_GROUP}
  tlsEnabled: true
EOF

echo "${CLUSTER_MANIFEST}" > memorydb_cluster.yaml

kubectl apply -f memorydb_cluster.yaml
if [ $? -ne 0 ]
then
  exit 1
fi

sleep 20

kubectl describe cluster/$CLUSTER_NAME

exit $?