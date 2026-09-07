# Traefik 41.3.0 cost/runtime baseline

This deployment is pinned to Traefik Helm chart `41.3.0` and keeps the existing EKS topology: two replicas, system-node scheduling, NLB service annotations, and `maxUnavailable: 1` PDB.

The controller values use:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: null
    memory: 512Mi

env:
  - name: GOMAXPROCS
    value: "2"
```

Chart `41.3.0` defaults `deployment.goMemLimitPercentage` to `0.9`, so with a memory limit configured it derives `GOMEMLIMIT` automatically. No separate `GOMEMLIMIT` override is needed.

The CPU request drives scheduling; removing the CPU limit lets Traefik burst when node CPU is available. The `512Mi` memory limit remains a hard ceiling and should be validated under representative peak traffic.

Render before rollout:

```bash
export CHART_VERSION=41.3.0
helm template traefik traefik/traefik \
  --namespace traefik \
  --version "$CHART_VERSION" \
  --values eks-values.yaml > /tmp/traefik-rendered.yaml
```

Confirm the rendered Traefik container has CPU request `100m`, memory request `128Mi`, no CPU limit, memory limit `512Mi`, `GOMAXPROCS="2"`, and chart-generated `GOMEMLIMIT`. Monitor memory working set, OOM kills, restarts, latency, and Karpenter/autoscaler behavior after rollout.
