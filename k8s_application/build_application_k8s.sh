#!/bin/sh

set -x
export CLUSTER_NAME=reinvent2022
export AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep -i region | cut -d'"' -f 4)
export AWS_ACCOUNT=$(curl -s  http://169.254.169.254/latest/dynamic/instance-identity/document | grep  accountId |  cut -d'"' -f 4)
export REDIS_PRIMARY_HOST=$(kubectl get cluster/$CLUSTER_NAME --template={{.status.clusterEndpoint.address}})

read -r -d '' SERVICE1_MANIFEST <<EOF
apiVersion: v1
kind: Service
metadata:
  name: inventory-service
spec:
  selector:
    app: inventoryapi
  ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000
EOF
echo "${SERVICE1_MANIFEST}" > service_inventory.yaml
kubectl apply -f service_inventory.yaml

read -r -d '' SERVICE2_MANIFEST <<EOF
apiVersion: v1
kind: Service
metadata:
  name: order-service
spec:
  selector:
    app: orderapi
  ports:
    - protocol: TCP
      port: 8001
      targetPort: 8001
EOF
echo "${SERVICE2_MANIFEST}" > service_order.yaml
kubectl apply -f service_order.yaml
sleep 20

export INVENTORY_SERVICE_SERVICE_HOST=$(kubectl get svc inventory-service  --template={{.spec.clusterIP}})
export ORDER_SERVICE_SERVICE_HOST=$(kubectl get svc order-service  --template={{.spec.clusterIP}})

read -r -d '' CLIENT_MANIFEST <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: client
  labels:
    app: client
spec:
  containers:
  - name: memdbreinventclient
    command: [ "/bin/bash", "-c", "--" ]
    args: [ "while true; do sleep 9999; done;" ]
    image: $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/reinvent2022:client
    env:
    - name: REDIS_HOST
      value: "${REDIS_PRIMARY_HOST}"
    - name: INVENTORY_API
      value: "http://${INVENTORY_SERVICE_SERVICE_HOST}:8000"
    - name: ORDER_API
      value: "http://${ORDER_SERVICE_SERVICE_HOST}:8001"
EOF

echo "${CLIENT_MANIFEST}" > client.yaml

kubectl apply -f client.yaml


read -r -d '' INVENTORY_MANIFEST <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: inventoryapi
  labels:
    app: inventoryapi
spec:
  containers:
  - name: inventoryapi
    image: $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/reinvent2022:inventoryapi
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

echo "${INVENTORY_MANIFEST}" > inventory_api.yaml

kubectl apply -f inventory_api.yaml

read -r -d '' ORDER_MANIFEST <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: orderapi
  labels:
    app: orderapi
spec:
  containers:
  - name: orderapi
    image: $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/reinvent2022:orderapi
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

echo "${ORDER_MANIFEST}" > order_api.yaml

kubectl apply -f order_api.yaml


read -r -d '' INVENTORYWORKER_MANIFEST <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: inventoryworker
  labels:
    app: inventoryworker
spec:
  containers:
  - name: inventoryworker
    image: $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/reinvent2022:inventoryworker
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

echo "${INVENTORYWORKER_MANIFEST}" > inventory_worker.yaml

kubectl apply -f inventory_worker.yaml

exit $?
