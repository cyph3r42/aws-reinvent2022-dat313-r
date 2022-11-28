#!/bin/sh

set -x

export SERVICE=ec2
export RELEASE_VERSION=`curl -sL https://api.github.com/repos/aws-controllers-k8s/$SERVICE-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4`

# aws ecr-public get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin public.ecr.aws
echo "" | helm registry login --username AWS --password-stdin public.ecr.aws

helm install --create-namespace -n $ACK_K8S_NAMESPACE ack-$SERVICE-controller \
  oci://public.ecr.aws/aws-controllers-k8s/$SERVICE-chart --version=$RELEASE_VERSION --set=aws.region=$AWS_REGION

if [ $? -ne 0 ]
then
  exit 1
fi

helm list --namespace $ACK_K8S_NAMESPACE -o yaml
kubectl --namespace ack-system get pods -l "app.kubernetes.io/instance=ack-$SERVICE-controller"

# To remove ...
# helm uninstall -n $ACK_K8S_NAMESPACE ack-$SERVICE-controller

exit $?