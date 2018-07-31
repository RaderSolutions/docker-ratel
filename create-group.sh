#!/bin/bash

CLIENT=${client_abbreviation}
LOCATION=${azure_location}
TENANT=${tenant}

CLIENTLC=`echo "${CLIENT}" | sed 's/\(.*\)/\L\1/'`
# Change these four parameters
AKS_PERS_STORAGE_ACCOUNT_NAME=$CLIENTLC"ratelstorage"
AKS_PERS_RESOURCE_GROUP="ratel"
AKS_PERS_LOCATION=${LOCATION}


### can't do these without interactivity afaict
#az login -t ${TENANT} 
#az group create --name $AKS_PERS_RESOURCE_GROUP --location $AKS_PERS_LOCATION 
### 

az aks install
# Create the storage account
az storage account create -n ${AKS_PERS_STORAGE_ACCOUNT_NAME} -g ${AKS_PERS_RESOURCE_GROUP} -l ${AKS_PERS_LOCATION} --sku Standard_LRS

# Export the connection string as an environment variable, this is used when creating the Azure file share
export AZURE_STORAGE_CONNECTION_STRING=`az storage account show-connection-string -n $AKS_PERS_STORAGE_ACCOUNT_NAME -g $AKS_PERS_RESOURCE_GROUP -o tsv`

# Create the file share
az storage share create -n etc-asterisk 
az storage share create -n var-spool-asterisk

# Get storage account key
STORAGE_KEY=$(az storage account keys list --resource-group $AKS_PERS_RESOURCE_GROUP --account-name $AKS_PERS_STORAGE_ACCOUNT_NAME --query "[0].value" -o tsv)

# Echo storage account name and key
echo Storage account name: $AKS_PERS_STORAGE_ACCOUNT_NAME
echo Storage account key: $STORAGE_KEY

kubectl create secret generic storagesecret --from-literal=azurestorageaccountname=${AKS_PERS_STORAGE_ACCOUNT_NAME} --from-literal=azurestorageaccountkey=${STORAGE_KEY}

