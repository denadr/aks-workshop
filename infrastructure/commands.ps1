# login to Azure Container Registry
az acr login --name "<registryName>"
# build and push Docker image to Azure Container Registry
az acr build -t "<name>" -r "<registryName>" ./

# download kubernetes credentials of the Azure Kubernetes Service
az aks get-credentials --resource-group "<group>" --name "<cluster>"
helm install "<release>" ./chart/

az aks update \
    --name "<cluster>" \
    --resource-group "<group>" \
    --attach-acr $(az acr show --name "<registryName>" --query "id" --output tsv)
az aks update \
    --name mainovaaksdemo-aks \
    --resource-group mainovaaksdemo-rg \
    --attach-acr $(az acr show --name mainovaaksdemocr --query "id" --output tsv)
az aks update -n mainovaaksdemo-aks -g mainovaaksdemo-rg --attach-acr mainovaaksdemocr
