#!/bin/sh

set -x

sleep 20

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
EKS_VPC_ID=$(aws --region $AWS_REGION eks describe-cluster --name $CLUSTER_NAME --query cluster.resourcesVpcConfig.vpcId)

EKS_SUBNET_CIDRS=$(aws --region $AWS_REGION ec2 describe-subnets \
  --filters "Name=vpc-id,Values=${EKS_VPC_ID}" "Name=tag:Name,Values=*Private*" \
  --query 'Subnets[*].CidrBlock' \
  --output text
)
# Adding current host for testing only
EKS_SUBNET_CIDRS="$EKS_SUBNET_CIDRS $(curl http://169.254.169.254/latest/meta-data/local-ipv4)/32"

MEMORYDB_SECURITYGROUP_NAME="memorydb-${CLUSTER_NAME}"

cat <<EOF > memorydb_securitygroup.yaml
apiVersion: ec2.services.k8s.aws/v1alpha1 
kind: SecurityGroup
metadata:
  name: "${MEMORYDB_SECURITYGROUP_NAME}"
spec:
  name: "${MEMORYDB_SECURITYGROUP_NAME}"
  description: "MemoryDB cluster Security Group access only from private subnets CIDRs"
  ingressRules:
  - fromPort: 6379
    toPort: 6379
    ipProtocol: TCP
    ipRanges:
$(printf "    - cidrIP: %s\n" ${EKS_SUBNET_CIDRS})
  vpcID: $EKS_VPC_ID 
  tags:
  - key: Name
    value: "kubectl-${MEMORYDB_SECURITYGROUP_NAME}/SecurityGroup"
EOF

sleep 20

#kubectl delete -f memorydb_securitygroup.yaml 
kubectl apply -f memorydb_securitygroup.yaml
if [ $? -ne 0 ]
then
  exit 1
fi

sleep 20

kubectl describe securitygroup/"${MEMORYDB_SECURITYGROUP_NAME}"

exit $?