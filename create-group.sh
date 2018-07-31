#!/bin/bash

CLIENT="CRL"
LOCATION="centralus"
TENANT=${tenant}
SUBNET=${subnet}

CLIENTLC=`echo "${CLIENT}" | sed 's/\(.*\)/\L\1/'`
# Change these four parameters
AKS_PERS_STORAGE_ACCOUNT_NAME=$CLIENTLC"ratelstorage"
AKS_PERS_RESOURCE_GROUP="ratel"
AKS_PERS_LOCATION=${LOCATION}
NODECOUNT=3
NODESIZE="Standard_A1_v2"
CLUSTERNAME="ratelaksclus01"
SUBNET=132


### can't do these without interactivity afaict
#az login -t ${TENANT} 
az group create --name $AKS_PERS_RESOURCE_GROUP --location $AKS_PERS_LOCATION 
### 


### Set up Storage
# Create the storage account
az storage account create -n ${AKS_PERS_STORAGE_ACCOUNT_NAME} -g ${AKS_PERS_RESOURCE_GROUP} -l ${AKS_PERS_LOCATION} --sku Standard_LRS --kind StorageV2

# Export the connection string as an environment variable, this is used when creating the Azure file share
export AZURE_STORAGE_CONNECTION_STRING=`az storage account show-connection-string -n $AKS_PERS_STORAGE_ACCOUNT_NAME -g $AKS_PERS_RESOURCE_GROUP -o tsv`

# Create the file share
az storage share create -n etc-asterisk 
az storage share create -n var-spool-asterisk

# Get storage account key
STORAGE_KEY=$(az storage account keys list --resource-group ${AKS_PERS_RESOURCE_GROUP} --account-name ${AKS_PERS_STORAGE_ACCOUNT_NAME} --query "[0].value" -o tsv)

# Echo storage account name and key
echo Storage account name: ${AKS_PERS_STORAGE_ACCOUNT_NAME}
echo Storage account key: ${STORAGE_KEY}

kubectl delete secret generic storagesecret
kubectl create secret generic storagesecret --from-literal=azurestorageaccountname=${AKS_PERS_STORAGE_ACCOUNT_NAME} --from-literal=azurestorageaccountkey=${STORAGE_KEY}

### Set up Networking
az network vnet create \
    -g ${AKS_PERS_RESOURCE_GROUP} \
    --location ${LOCATION} \
    -n ratelVnet \
    --address-prefix 10.247.0.0/16 \
    --subnet-name aksSubnet \
    --subnet-prefix 10.247.${SUBNET}.0/24

subnetId=`az network vnet subnet list -g ${AKS_PERS_RESOURCE_GROUP} --vnet-name ratelVnet --query [].id --output tsv`

### Create Kubernetes Cluster
aksLatestVersion=`az aks get-versions --location ${LOCATION} -o table | grep "^------" -A 1 | tail -1 | awk {'print $1'}`
az aks create \
    --resource-group ${AKS_PERS_RESOURCE_GROUP} \
    --name ${CLUSTERNAME} \
    --node-count ${NODECOUNT} \
    --node-vm-size ${NODESIZE} \
    --generate-ssh-keys \
    --vnet-subnet-id ${subnetId} \
    --kubernetes-version ${aksLatestVersion}

which kubectl || az aks install-cli

### Deploy pods to cluster
kubectl create -f https://

