# Lesson 1 · OCI Registries

Every earlier lesson distributed charts one of two ways: installing straight from a chart's local directory (`helm install webapp .`), or pulling from a classic **chart repository** — a plain web server hosting an `index.yaml` plus a pile of `.tgz` files (`helm repo add bitnami ...` back in Module 1). This lesson covers the modern third option: **OCI registries**.

## Why OCI

OCI (Open Container Initiative) registries are the same kind of server that hosts container images — Docker Hub, GitHub Container Registry (GHCR), Amazon ECR, Google Artifact Registry, Harbor, and so on. Since Helm 3.8, Helm can push and pull charts to/from any OCI registry, treating a chart exactly like another kind of artifact alongside container images.

This matters in practice because:

- **No separate hosting.** A classic chart repo needs its own web server serving `index.yaml` (and someone has to regenerate and re-host that index every time a chart is added or updated — see Module 2's `helm repo index`). An OCI registry needs none of that — `helm push` is enough.
- **Reuse existing infrastructure.** Most organizations already run or pay for a container registry with auth, RBAC, and retention policies. Charts can live right next to the images they deploy, under the same access control.
- **This is where the ecosystem is heading.** Bitnami and other major chart publishers now distribute primarily via OCI. Artifact Hub increasingly points at `oci://` references instead of classic repo URLs.

The tradeoff: OCI registries have no `index.yaml` to browse, so there's no `helm search repo` equivalent — you either already know the exact `oci://registry/path/chart` reference and version, or you discover it some other way (a registry's own UI/API, your organization's docs, Artifact Hub).

## The commands

| Command | What it does |
|---|---|
| `helm registry login <registry>` | Authenticates to a registry (skip for an unauthenticated local registry, like this lesson's) |
| `helm package <chart-dir>` | Builds a chart into a versioned `.tgz` — the same artifact classic repos use, OCI just stores it differently |
| `helm push <chart>.tgz oci://<registry>/<path>` | Uploads the packaged chart to the registry |
| `helm pull oci://<registry>/<path>/<chart> --version X` | Downloads a chart's `.tgz` from the registry to your current directory |
| `helm show values oci://.../<chart> --version X` | Reads a chart's default values straight from the registry, no local pull needed |
| `helm install <release> oci://.../<chart> --version X` | Installs directly from the registry — no `helm pull` step required at all |

One flag you'll see repeatedly in this lesson: **`--plain-http`**. Real registries (GHCR, ECR, Docker Hub, etc.) serve HTTPS, so you'd never need it against them. It exists so you can point Helm at an HTTP-only registry — exactly the throwaway local one this exercise sets up.

## Exercise

Go to [exercise.md](exercise.md). You'll run a local OCI registry in a container, then package, push, pull, and install your `webapp` chart through it — no cloud account or real registry needed.
