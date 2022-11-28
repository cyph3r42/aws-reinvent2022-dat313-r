#!/bin/bash

set -x
wget https://ee-assets-prod-us-east-1.s3.amazonaws.com/modules/6e8a4016eaa1459794cb3bd2842c64ae/v1/applicationfiles.zip
unzip -q applicationfiles.zip

export AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep -i region | cut -d'"' -f 4)
export AWS_ACCOUNT=$(curl -s  http://169.254.169.254/latest/dynamic/instance-identity/document | grep  accountId |  cut -d'"' -f 4)

# Steps Create the container images and push it to repo
sudo docker login --username AWS --password $(aws ecr get-login-password --region $AWS_REGION) $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com
#Creating the main repository
aws ecr create-repository --repository-name reinvent2022 --region $AWS_REGION

#Creating and pushing inventory API image
cd applicationfiles/inventory
cp Dockerfile_uvicon_inventory Dockerfile
sudo docker build . -t inventoryapi
sudo docker tag inventoryapi:latest $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/reinvent2022:inventoryapi
sudo docker push $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/reinvent2022:inventoryapi

#Creating and pushing inventory worker image
cp Dockerfile_inventory Dockerfile
sudo docker build . -t inventoryworker
sudo docker tag inventoryworker:latest $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/reinvent2022:inventoryworker
sudo docker push $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/reinvent2022:inventoryworker
#Creating and pushing the order image
cd ~/applicationfiles/order
cp Dockerfile_uvicon_order Dockerfile
sudo docker build . -t orderapi
sudo docker tag orderapi:latest $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/reinvent2022:orderapi
sudo docker push $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/reinvent2022:orderapi

#Creating and pushing the order image
cp Dockerfile_order Dockerfile
sudo docker build . -t orderworker
sudo docker tag orderworker:latest $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/reinvent2022:orderworker
sudo docker push $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/reinvent2022:orderworker

#Creating and pushing the client image

cd ~/clientfiles/
sudo docker build . -t client
sudo docker tag client:latest $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/reinvent2022:client
sudo docker push $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/reinvent2022:client
