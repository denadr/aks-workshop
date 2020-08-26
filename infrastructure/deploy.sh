az login
az account set --subscription "AKS Cluster Mainova"

terraform init
terraform apply --auto-approve

az aks update --name $(terraform output aksName) \
    --resource-group $(terraform output resourceGroupName) \
    --attach-acr $(terraform output registryName)


az aks update --name  --resource-group $(terraform output resourceGroupName) --attach-acr $(terraform output registryName)