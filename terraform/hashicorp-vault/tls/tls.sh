#!/bin/bash
set -e

NAMESPACE="vault"
SECRET_NAME="vault-tls"
VALIDITY_DAYS=$((100 * 365)) # 100 years

# Cleanup function to remove existing resources
cleanup() {
  kubectl delete secret $SECRET_NAME -n $NAMESPACE --ignore-not-found
}

# Run cleanup before starting the process
cleanup

# Create a self-signed CA
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days $VALIDITY_DAYS -out ca.crt -subj "/CN=Vault CA"

# Create the private key for Vault
openssl genrsa -out vault.key 2048

# Create the CSR configuration file
cat > vault-csr.conf <<EOF
[req]
default_bits = 2048
prompt = no
encrypt_key = yes
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[ dn ]
CN = vault.vault.svc.cluster.local

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.vault-internal
DNS.2 = *.vault-internal.vault.svc.cluster.local
DNS.3 = *.vault
DNS.4 = vault
DNS.5 = vault-active.vault.svc.cluster.local
IP.1 = 127.0.0.1
EOF

# Generate the CSR
openssl req -new -key vault.key -out vault.csr -config vault-csr.conf

# Sign the CSR with our CA
openssl x509 -req -in vault.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out vault.crt -days $VALIDITY_DAYS -sha256 -extfile vault-csr.conf -extensions v3_req

# Verify the certificate
openssl verify -CAfile ca.crt vault.crt

# Create the Kubernetes secret
kubectl create secret generic $SECRET_NAME \
   -n $NAMESPACE \
   --from-file=vault.key=vault.key \
   --from-file=vault.crt=vault.crt \
   --from-file=vault.ca=ca.crt

echo "TLS secret created successfully with 100-year validity."

# Clean up temporary files
rm ca.key vault.csr vault-csr.conf