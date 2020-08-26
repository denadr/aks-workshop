# Add the official stable repository
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
# Use Helm to deploy an NGINX ingress controller
helm install ingress-nginx ingress-nginx/ingress-nginx





curl "http://<ip>:<port>/<path>"





az login
az account set --subscription "AKS Cluster Mainova"

cd ./infrastructure/
terraform init
terraform apply --auto-approve
cd ./../

az acr login --name mainovaaksdemocr
az aks get-credentials --resource-group mainovaaksdemo-rg --name mainovaaksdemo-aks

az acr build -t comments -r mainovaaksdemocr ./comments/
helm install comments ./comments/chart/

az acr build -t posts -r mainovaaksdemocr ./posts/
helm install posts ./posts/chart/

az acr build -t users -r mainovaaksdemocr ./users/
helm install users ./users/chart/

helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx
kubectl apply -f ./ingress/ingress.yaml
