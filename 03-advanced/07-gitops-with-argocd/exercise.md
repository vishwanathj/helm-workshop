# Exercise 7 · Sync, Drift, and Self-Heal

## Part A — install Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side --force-conflicts
kubectl wait --for=condition=Available deployment --all -n argocd --timeout=180s
kubectl get pods -n argocd
```
All pods should reach `Running`/`1/1`. If your machine is memory-constrained, this is a good moment to check your local cluster's resource headroom (a `kind`-on-Podman setup may need its VM's memory bumped, e.g. `podman machine set --memory 4096` after `podman machine stop`, then `podman machine start` again).

## Part B — point Argo CD at a real chart

You need a git repo you can read (and, for Part D, write to). If you've been following this workshop from its own public repo and have push access to it (or a fork of it), you can use it directly — otherwise, fork it first.

Create `argocd-app.yaml`:
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

Apply it and watch Argo CD do the rest:
```bash
kubectl apply -f argocd-app.yaml
kubectl get application -n argocd
```
Give it a few seconds, then check again — `SYNC STATUS` should read `Synced` and `HEALTH STATUS` should read `Healthy`, with no `helm install` ever run by you:
```bash
kubectl get application webapp -n argocd
kubectl get deployment,service,pod -n helm-gitops
```

## Part C — break it on purpose, watch self-heal fix it

```bash
kubectl scale deployment webapp -n helm-gitops --replicas=5
kubectl get deployment webapp -n helm-gitops -o jsonpath='{.spec.replicas}'
```
Wait a few seconds and check again:
```bash
kubectl get deployment webapp -n helm-gitops -o jsonpath='{.spec.replicas}'
kubectl get events -n helm-gitops --sort-by='.lastTimestamp' | tail -10
```
The replica count should be back to what the chart declares (1), and the events should show pods being created and then killed as Argo CD reconciled — all without you running a single `helm` or `kubectl apply` command yourself. This is `selfHeal: true` doing exactly what Module 1 Lesson 7's rollback exercise did by hand, except continuously and automatically.

## Part D — change it for real, through git

This is the actual GitOps loop, and it requires write access to the repo you pointed `source.repoURL` at:

1. Edit `values.yaml` for the chart at that path (`01-basics/05-your-first-chart/solution/webapp/values.yaml` if you used this workshop's own layout) — bump `replicaCount` to something new, or change `image.tag`.
2. Commit and push it.
3. Watch Argo CD pick it up (by default it polls every few minutes; to see it immediately, either wait, or trigger a manual refresh: `kubectl patch application webapp -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'`).
4. Confirm the cluster now matches your new commit:
   ```bash
   kubectl get deployment webapp -n helm-gitops -o jsonpath='{.spec.replicas}'
   ```

**This step really does push a commit to whatever repo you pointed at.** If you don't want to touch this workshop's own history, do this against your own fork, or point `path` at a throwaway chart in a personal scratch repo instead.

## Part E — clean up

```bash
kubectl delete -f argocd-app.yaml
kubectl delete namespace helm-gitops
kubectl delete namespace argocd
```
Deleting the `Application` does **not** delete Argo CD itself — only the one release it was managing. The last command removes Argo CD's entire control plane.

## Questions

<details>
<summary>Q1: Why did <code>kubectl apply</code> (without <code>--server-side</code>) fail on Argo CD's install manifest, when it's worked fine on every other manifest in this workshop?</summary>

Classic `kubectl apply` stores the entire previous manifest as a `kubectl.kubernetes.io/last-applied-configuration` annotation on the object, so it can compute a three-way diff on the next apply. Kubernetes caps annotation size at 256KiB. Argo CD's `ApplicationSet` CRD schema is large enough that this one annotation alone exceeds that cap. `--server-side` apply doesn't work this way at all — the API server tracks which fields each "manager" (you, another controller) owns directly, with no giant annotation involved, so the size limit never comes into play. Every other manifest in this workshop has simply been small enough never to hit this.
</details>

<details>
<summary>Q2: In Part B, what actually rendered the Helm chart into Kubernetes manifests — was it your local <code>helm</code> CLI?</summary>

No — Argo CD's own `repo-server` component clones the git repo internally and runs Helm's rendering logic itself (it embeds Helm as a library, not by shelling out to a `helm` binary on your machine). Your local `helm` CLI was never invoked for this at all; everything happened inside the `argocd-repo-server` pod running in your cluster.
</details>

<details>
<summary>Q3: If you set <code>prune: false</code> instead of <code>true</code>, what would change about Part D's behavior if you'd also deleted a template file from the chart in git?</summary>

With `prune: true` (as configured), deleting a template from the chart in git causes Argo CD to also delete the corresponding live Kubernetes resource on the next sync — the cluster fully matches git, including removals. With `prune: false`, Argo CD would report the Application as `OutOfSync` (it can see the live resource is no longer declared anywhere in git) but would leave that resource running rather than deleting it — a safer-by-default stance some teams prefer, trading full git-fidelity for protection against an accidental deletion in git silently taking down a live resource.
</details>

---

**Module 3 · Advanced complete.** You've covered every topic originally planned: OCI registries, chart signing, library charts, custom plugins, Helmfile, chart testing/CI, and GitOps — the same rigor and hands-on verification as Modules 1 and 2, applied to the tools that sit around Helm itself in a real deployment pipeline.
