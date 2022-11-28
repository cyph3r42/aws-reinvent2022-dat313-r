export PATH=$PATH:/usr/local/bin:.
export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export CLUSTER_NAME=reinvent2022
export ACK_K8S_NAMESPACE=ack-system