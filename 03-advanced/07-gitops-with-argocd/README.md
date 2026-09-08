# Lesson 7 · GitOps with Argo CD

Every lesson before this one had *you* run `helm install`/`helm upgrade` from your own machine, at a moment you chose. **GitOps** flips that: a controller running *inside* your cluster continuously watches a git repository, and keeps the cluster's actual state matching whatever that repo declares — no person, and no CI pipeline, ever runs `helm install` by hand against production again. Git becomes the single source of truth; the only way to change what's deployed is to change what's committed.

[Argo CD](https://argo-cd.readthedocs.io/) is the most widely-used tool for this in the Kubernetes ecosystem, and it understands Helm charts natively — point it at a git path containing a `Chart.yaml` and it renders and applies it exactly like `helm template` would, with no separate Argo-specific packaging step.

## Installing Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side --force-conflicts
```

**Note the `--server-side` flag.** A plain `kubectl apply` on Argo CD's install manifest fails on this environment with:
```
The CustomResourceDefinition "applicationsets.argoproj.io" is invalid: metadata.annotations: Too long: may not be more than 262144 bytes
```
That's `kubectl apply`'s classic-mode `last-applied-configuration` annotation hitting Kubernetes' annotation size ceiling — Argo CD's `ApplicationSet` CRD is large enough to trip it. `--server-side` apply doesn't use that annotation at all (it tracks field ownership server-side instead), so it doesn't hit the limit. This is a real, commonly-hit gotcha with very large CRDs, not specific to this workshop.

Wait for it to come up:
```bash
kubectl wait --for=condition=Available deployment --all -n argocd --timeout=180s
kubectl get pods -n argocd
```

## The core object: `Application`

Everything Argo CD manages is described by one Custom Resource:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: webapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/<your-username>/helm-workshop.git
    targetRevision: main
    path: 01-basics/05-your-first-chart/solution/webapp
  destination:
    server: https://kubernetes.default.svc
    namespace: helm-gitops
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
      - CreateNamespace=true
```

- **`source`** — where the desired state lives: a git repo, a revision (branch, tag, or commit), and a path within it. Argo CD auto-detects that path contains a Helm chart (it sees `Chart.yaml`) with no extra configuration needed.
- **`destination`** — where to apply it. `https://kubernetes.default.svc` means "this same cluster Argo CD is running in" (Argo CD can also manage *other* clusters from one central instance, out of scope here).
- **`syncPolicy.automated`** — without this block, Argo CD only shows you an `OutOfSync` status and waits for a human to click "Sync" (or run `argocd app sync`). With it:
  - **`selfHeal: true`** — if anything in the cluster drifts from git (someone runs `kubectl scale` or `kubectl edit` by hand), Argo CD reverts it automatically, typically within seconds.
  - **`prune: true`** — if a resource is *removed* from the chart/repo, Argo CD deletes the corresponding live resource, not just stops updating it.
  - **`CreateNamespace=true`** — creates `destination.namespace` if it doesn't already exist.

## Accessing the UI (optional)

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Then browse to `https://localhost:8080` (self-signed cert — your browser will warn you, that's expected for a local instance). Username `admin`; get the initial password with:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## Exercise

Go to [exercise.md](exercise.md). You'll install Argo CD, point it at a real Helm chart in a git repo, watch it sync automatically, and then intentionally drift the cluster to watch self-heal correct it.
