# Exercise 3 · Install a Public Chart

## Tasks

1. Add the Bitnami chart repository (one of the most widely used public repos):
   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo update
   ```

2. Search it for an `nginx` chart:
   ```bash
   helm search repo bitnami/nginx
   ```

3. Look at what's configurable before installing:
   ```bash
   helm show values bitnami/nginx | less
   ```
   Find the `service.type` and `replicaCount` fields (use `/` to search within `less`, `q` to quit).

4. Install it as a release named `my-nginx`, in a dedicated namespace `helm-basics` (created automatically with `--create-namespace`):
   ```bash
   helm install my-nginx bitnami/nginx --namespace helm-basics --create-namespace
   ```

5. Confirm it's running:
   ```bash
   helm list --namespace helm-basics
   kubectl get pods --namespace helm-basics
   ```
   Wait until the pod shows `Running` and `1/1` ready (may take a minute to pull the image).

6. Inspect the release:
   ```bash
   helm status my-nginx --namespace helm-basics
   helm get values my-nginx --namespace helm-basics
   ```
   Note: `helm get values` by default shows only the values *you* overrode — which is none, so it's empty. That's expected.

7. Clean up — uninstall the release:
   ```bash
   helm uninstall my-nginx --namespace helm-basics
   kubectl get pods --namespace helm-basics
   ```
   The pods should terminate and disappear.

## Questions

<details>
<summary>Q1: What's the difference between the chart name (<code>bitnami/nginx</code>) and the release name (<code>my-nginx</code>)?</summary>

`bitnami/nginx` identifies which chart (template) to install, from which repo. `my-nginx` is the name *you* gave to this particular installation. You could install `bitnami/nginx` again with a different release name (e.g., `my-nginx-2`) in the same or a different namespace, and get a second, independent release.
</details>

<details>
<summary>Q2: Why did <code>helm get values</code> return empty even though the chart clearly has many default values (replicaCount, service.type, etc.)?</summary>

`helm get values` shows only the values you explicitly overrode at install time via `--set` or `-f`. Since you installed with no overrides, it's empty. The chart's *defaults* (which are what's actually running) are visible via `helm show values bitnami/nginx` or `helm get values my-nginx --all`.
</details>

Next: [Lesson 4 · Chart Anatomy](../04-chart-anatomy/)
