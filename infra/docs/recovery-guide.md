# SkillPulse Cluster Recovery

## Reconnect to EKS

aws eks update-kubeconfig \
  --region us-west-2 \
  --name skillpulse-cluster

## Verify Cluster

kubectl get nodes

## Install ArgoCD

kubectl create namespace argocd

kubectl apply -n argocd -f \
https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

## Port Forward

kubectl port-forward svc/argocd-server \
-n argocd 8080:443

## Login

argocd login localhost:8080 --insecure

## Sync Apps

argocd app sync skillpulse-dev --prune
argocd app sync skillpulse-staging --prune
argocd app sync skillpulse-prod --prune
