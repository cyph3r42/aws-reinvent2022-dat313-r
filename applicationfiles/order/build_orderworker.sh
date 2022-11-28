set -x
export REDIS_PRIMARY_HOST=$(kubectl get cluster/reinvent2022 --template={{.status.clusterEndpoint.address}})
export AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep -i region | cut -d'"' -f 4)
export AWS_ACCOUNT=$(curl -s  http://169.254.169.254/latest/dynamic/instance-identity/document | grep  accountId |  cut -d'"' -f 4)
export INVENTORY_SERVICE_SERVICE_HOST=$(kubectl get svc inventory-service  --template={{.spec.clusterIP}})
export ORDER_SERVICE_SERVICE_HOST=$(kubectl get svc order-service  --template={{.spec.clusterIP}})

read -r -d '' ORDERWORKER_MANIFEST <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: orderworker
  labels:
    app: orderworker
spec:
  containers:
  - name: orderworker
    image: $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/reinvent2022:orderworker
    env:
    - name: REDIS_HOST
      value: "${REDIS_PRIMARY_HOST}"
    - name: REDIS_PORT
      value: "6379"
    - name: BACKEND_HOST
      value: "http://${INVENTORY_SERVICE_SERVICE_HOST}:8000"
    - name: FRONTEND_HOST
      value: "http://${INVENTORY_SERVICE_SERVICE_HOST}:3000"
EOF

echo "${ORDERWORKER_MANIFEST}" > order_worker.yaml
kubectl apply -f order_worker.yaml
exit $?
