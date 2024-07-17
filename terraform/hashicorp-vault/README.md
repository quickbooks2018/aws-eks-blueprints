# AWS HashiCorp Vault for aks

- 1st Run Bash Script these will certs in kubernetes secret vault namespace
```bash
k create ns vault

cd tls
chmod +x tls.sh
./tls.sh

or run cloudflare-tls.sh

kubectl create secret generic vault-tls \
  --namespace vault \
  --from-file=vault.key=/mnt/tls/vault-key.pem \
  --from-file=vault.crt=/mnt/tls/vault.pem \
  --from-file=vault.ca=/mnt/tls/ca.pem
```

- 2nd Install the HashiCorp Vault Helm chart
```bash
helm repo ls
helm repo add hashicorp https://helm.releases.hashicorp.com
helm search repo hashicorp
helm search repo hashicorp/vault --versions
helm show values hashicorp/vault --version 0.28.0
# helm show values hashicorp/vault --version 0.28.0 > vault-values.yaml
helm repo update

helm -n vault upgrade --install vault hashicorp/vault --version 0.28.0 --values eks-values.yaml --create-namespace --wait
```

- 4th Run the KMS this will create the serivce account with oidc and overide the existing vault service account
```bash
bash -uvx ./kms.sh
```

- 5th 
```bash
helm -n vault upgrade --install vault hashicorp/vault --version 0.28.0 --values eks-values.yaml --create-namespace --wait 
```

- Manually add annotation 
```bash
# From cloudformation stack see the role get the arn

k edit sa/vault -n vault
eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>



apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::058264369563:role/eksctl-cloudgeeks-eks-dev-addon-iamserviceacc-Role1-8z5zkEXDHGO4
    meta.helm.sh/release-name: vault
    meta.helm.sh/release-namespace: vault
  creationTimestamp: "2024-07-17T05:23:26Z"
  labels:
    app.kubernetes.io/instance: vault
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: vault
    helm.sh/chart: vault-0.28.0
  name: vault
  namespace: vault
  resourceVersion: "43591"
  uid: 536c89fa-48b3-4938-95de-f6d1d749b17d
```

- Unseal the Vault & copy the keys in secure place
```bash
kubectl -n vault exec -it vault-0 -- vault operator init
```

### Enable k8s auth

Note: When pod run as a service account, it will have a token mounted at /var/run/secrets/kubernetes.io/serviceaccount/token. This token is used to authenticate with the Kubernetes API. The token is scoped to a specific namespace, so it can only access resources in that namespace.

```bash
kubectl -n vault exec -it vault-0 -- sh

vault login
vault auth enable kubernetes

vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host=https://kubernetes.default.svc \
    kubernetes_ca_cert=@/vault/tls/vault.ca
```

- Error: failed to login add (ca.pem) simply rerun the command
```bash
vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host=https://kubernetes.default.svc \
    kubernetes_ca_cert=@/vault/tls/vault.ca
```
- Application to Access Secrets in Vault, we need to setup the policy in vault, in order inject secrets in application pod
- Basic Secret Injection
- In order for us to start using secrets in vault, we need to setup a policy.

```bash
#Create a role for our app

kubectl -n vault exec -it vault-0 -- sh 

vault write auth/kubernetes/role/basic-secret-role \
   bound_service_account_names="basic-secret" \
   bound_service_account_namespaces="example-app" \
   policies="basic-secret-policy" \
   ttl=1h
```

- vault
```bash
vault read auth/kubernetes/config
```

- The above maps our Kubernetes service account, used by our pod, to a policy. Now lets create the policy to map our service account to a bunch of secrets.

```bash
kubectl -n vault exec -it vault-0 -- sh 

cat <<EOF > /home/vault/app-policy.hcl
path "secret/data/basic-secret/*" {
  capabilities = ["read"]
}
EOF
vault policy write basic-secret-policy /home/vault/app-policy.hcl
```

- Vault Policy troubleshooting
```bash
vault kv get secret/data/basic-secret/helloworld
```

- Now our service account for our pod can access all secrets under secret/basic-secret/* Lets create some secrets.

```bash
kubectl -n vault exec -it vault-0 -- sh 
vault secrets enable -path=secret/ kv-v2
vault kv put secret/basic-secret/helloworld username=dbuser password=12345678
```

- Lets deploy our app and see if it works
```bash
kubectl apply -f ./app/deployment.yaml
kubectl -n example-app get pods
```

- issues
- https://github.com/hashicorp/vault/issues/19952
