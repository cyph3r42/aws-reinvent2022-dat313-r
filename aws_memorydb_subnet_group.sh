#!/bin/sh

set -x

sleep 20

EKS_VPC_ID=$(aws --region $AWS_REGION eks describe-cluster --name $CLUSTER_NAME --query cluster.resourcesVpcConfig.vpcId)

EKS_SUBNET_IDS=$(aws --region $AWS_REGION ec2 describe-subnets \
  --filters "Name=vpc-id,Values=${EKS_VPC_ID}" "Name=tag:Name,Values=*Private*" \
  --query 'Subnets[*].SubnetId' \
  --output text
)

MEMORYDB_SUBNETGROUP_NAME="memorydb-${CLUSTER_NAME}-sg"

cat <<EOF > memorydb_subnetgroup.yaml
apiVersion: memorydb.services.k8s.aws/v1alpha1
kind: SubnetGroup

metadata:
  name: "${MEMORYDB_SUBNETGROUP_NAME}"

spec:
  name: "${MEMORYDB_SUBNETGROUP_NAME}"
  description: "MemoryDB cluster subnet group"
  subnetIDs:
$(printf "    - %s\n" ${EKS_SUBNET_IDS})
EOF

kubectl apply -f memorydb_subnetgroup.yaml
if [ $? -ne 0 ]
then
  exit 1
fi

sleep 20

kubectl describe subnetgroup "${MEMORYDB_SUBNETGROUP_NAME}"

exit $?