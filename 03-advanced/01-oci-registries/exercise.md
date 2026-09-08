# Exercise 1 · Push, Pull & Install via OCI

Work in a fresh directory, e.g. `/tmp/webapp-oci`, with a copy of the `webapp` chart (with the ConfigMap) from Module 1 — see [01-basics/06-values-and-templates/solution/webapp-with-configmap/](../../01-basics/06-values-and-templates/solution/webapp-with-configmap/).

```bash
mkdir -p /tmp/webapp-oci
cp -R /path/to/webapp-with-configmap/* /tmp/webapp-oci/
cd /tmp/webapp-oci
```

## Part A — run a local OCI registry

You don't need a cloud account for this exercise — the open-source [Distribution](https://distribution.github.io/distribution/) registry (the same project Docker Hub itself runs) works as a plain local container, and has spoken the OCI protocol Helm needs since v2.8.0.

```bash
docker run -d -p 5000:5000 --name workshop-registry docker.io/library/registry:2
# or, if you're on Podman:
podman run -d -p 5000:5000 --name workshop-registry docker.io/library/registry:2
```

Confirm it's up:
```bash
curl http://localhost:5000/v2/
```
You should get back `{}` with no error — an empty but responsive registry.

## Part B — package and push

1. Package the chart into a versioned `.tgz` (same command as any chart, OCI or not):
   ```bash
   helm package .
   ```
   This produces `webapp-0.1.0.tgz` (the version comes from `Chart.yaml`).

2. Push it to your local registry, under a made-up path `workshop/webapp`:
   ```bash
   helm push webapp-0.1.0.tgz oci://localhost:5000/workshop --plain-http
   ```
   You should see `Pushed: localhost:5000/workshop/webapp:0.1.0` plus a `Digest:` line — the registry now has your chart stored as an OCI artifact, content-addressed by that digest.

## Part C — pull and inspect

1. In a different scratch directory, pull it back down:
   ```bash
   mkdir /tmp/oci-pull-test && cd /tmp/oci-pull-test
   helm pull oci://localhost:5000/workshop/webapp --version 0.1.0 --plain-http
   ls
   ```
   You get back the exact same `webapp-0.1.0.tgz` — round-tripped through the registry.

2. You don't even need to pull first to inspect a chart — `helm show` reads straight from the registry:
   ```bash
   helm show values oci://localhost:5000/workshop/webapp --version 0.1.0 --plain-http
   ```
   This prints the chart's default `values.yaml`, fetched on the fly.

## Part D — install directly from OCI

No `helm pull` needed at all — `helm install` can target an `oci://` reference directly, exactly like a local path or a classic repo chart:

```bash
helm install webapp-from-oci oci://localhost:5000/workshop/webapp --version 0.1.0 --plain-http \
  --namespace helm-advanced --create-namespace \
  --set html.message="Installed straight from OCI!"
```

Verify:
```bash
kubectl get pods --namespace helm-advanced
kubectl get configmap webapp-html --namespace helm-advanced -o jsonpath='{.data.index\.html}'
```
You should see your custom message in the ConfigMap's rendered HTML — proving the values override was applied on an install sourced entirely from the registry.

## Part E — clean up

```bash
helm uninstall webapp-from-oci --namespace helm-advanced
kubectl delete namespace helm-advanced
docker stop workshop-registry && docker rm workshop-registry
# or: podman stop workshop-registry && podman rm workshop-registry
```

The registry container had no persistent volume, so stopping/removing it discards everything you pushed — that's fine, it was only ever a throwaway for this exercise.

## Questions

<details>
<summary>Q1: Why did none of this require <code>helm registry login</code>?</summary>

The `registry:2` image runs with no authentication configured by default — anyone who can reach port 5000 can push and pull. Real registries (GHCR, ECR, Docker Hub, a company's private Harbor instance) require `helm registry login <registry> -u <user> --password-stdin` before push/pull, exactly like `docker login`. This exercise skips it only because the local throwaway registry has no auth layer at all — never run a registry like this reachable from outside your own machine.
</details>

<details>
<summary>Q2: Why is there no <code>helm search</code> for OCI registries, the way <code>helm search repo</code> works for classic repos?</summary>

Classic chart repos publish a single `index.yaml` listing every chart and version they host — that's the file `helm search repo` actually searches. OCI registries have no equivalent single "table of contents" endpoint in general (the OCI distribution spec supports listing tags for a *known* repository path, but not discovering unknown paths). In practice, you either already know the reference (from your organization's docs, a README, Artifact Hub) or you browse the registry's own UI/API — there's no generic cross-registry search the way `helm search repo` provides across your added repos.
</details>

<details>
<summary>Q3: What's actually stored in the registry after <code>helm push</code> — is it a Docker image?</summary>

No — it's an OCI artifact, which is a more general concept than a container image. Both a chart and a container image are stored as a manifest plus one or more content-addressed blobs, using the same registry API and storage model, but a chart's blob is a `.tgz` of YAML templates, not a filesystem layer. That's the whole point of Helm adopting OCI: charts and images can share the exact same registry infrastructure without the registry needing to know anything Helm-specific.
</details>

Next: [Lesson 2 · Chart Provenance & Signing](../02-chart-provenance-and-signing/)
