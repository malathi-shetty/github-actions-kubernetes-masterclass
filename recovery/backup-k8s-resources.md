Run these ONE BY ONE.

Dev:

kubectl get all -n skillpulse-dev -o yaml > recovery/dev-all.yaml

Staging:

kubectl get all -n skillpulse-staging -o yaml > recovery/staging-all.yaml

Prod:

kubectl get all -n skillpulse-prod -o yaml > recovery/prod-all.yaml

Backup ArgoCD Apps:

kubectl get applications -n argocd -o yaml > recovery/argocd-apps.yaml

Backup Monitoring

kubectl get all -n monitoring -o yaml > recovery/monitoring.yaml

Save Secrets

kubectl get secrets -A -o yaml > recovery/secrets.yaml

Do NOT make public repo if this is committed.

Backup kubeconfig

Very important.

cp ~/.kube/config recovery/kubeconfig-backup


What happens if EC2 dies?
aws eks update-kubeconfig --region us-west-2 --name skillpulse-cluster

What happens if cluster dies?

You recreate:

EKS cluster
ArgoCD
Monitoring

Then ArgoCD rebuilds workloads from GitHub.

That’s GitOps.
