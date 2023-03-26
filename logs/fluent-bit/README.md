# cloudgeeks.ca

- Update Terraform with Role ARN of the fluent-bit
```policy
"arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/fluent-bit"
```
- Eks Logging

- Redis Container
```
kubectl run redis --image=redis --port=6379
```

- add a filter in kibana to filter out the redis container logs select "kubernetes.container_name: redis"

- Update file 2-service-account.yaml line number 8 (fluent-bit ARN)

- Update file 3-fluent-bit.yaml line number 78 & 82 (78 endpoint of elasticsearch & 82 is aws region)
