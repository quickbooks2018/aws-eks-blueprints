# AWS EKS Secrets

- step 1 create a eks service account with terraform

- Step2 Install CSI Secret Store Provider for AWS https://github.com/aws/secrets-store-csi-driver-provider-aws

```helm
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install -n kube-system csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver
```

- Step 3 Install the aws provider
```kubectl
kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml
```

- CSI DRIVER Commands
```kubectl
kubectl get csidrivers
kubectl get csinode
```

- CSI DaemonSet
```kubectl
kubectl get daemonset -A
```