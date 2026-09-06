# Lesson 7 · Packaging & Hosting Your Own Chart Repository

Every chart you've installed from `bitnami/...` in this workshop came from a **chart repository** — and a chart repository turns out to be a surprisingly plain thing: a directory of packaged `.tgz` charts plus one generated `index.yaml` file, served over plain HTTP(S). No database, no special server software required.

## Packaging a chart

```bash
helm package /tmp/webapp -d /tmp/chart-repo
```

This produces `/tmp/chart-repo/webapp-<version>.tgz`, where `<version>` comes straight from `Chart.yaml`. If your chart has dependencies already vendored in `charts/` (Lesson 4), they're bundled into this same `.tgz` automatically — one file, fully self-contained.

**Bump `version` in `Chart.yaml` before every new package.** Two different `.tgz` files with the same chart name and version is a broken state a chart repo can't represent — version is the only thing that tells consumers (and Helm itself) which package they're getting. This is separate from `appVersion`, which tracks the version of the *application* the chart deploys and can change independently.

## Building the index

```bash
helm repo index /tmp/chart-repo --url https://example.com/charts
```

This scans every `.tgz` in the directory and writes `index.yaml` — one entry per chart version, each with a name, version, digest, and a download URL built from the `--url` you pass (this is the base URL the repo will actually be served from, not a filesystem path — get it wrong and every install from this repo will 404). Adding a new chart version later means re-running `helm package` into the same directory, then re-running `helm repo index` — with `--merge index.yaml` so it keeps older entries around instead of only knowing about the newest package on disk.

## Serving it

A chart repository has no required server-side logic — any static file host works: S3/GCS with public read, GitHub Pages, or (for this lesson) a plain local HTTP server. **Helm does not support adding a `file://` path directly as a repo** (`helm repo add` needs an actual `http(s)://` or `oci://` endpoint) — even a fully local, single-machine setup needs *something* speaking HTTP in front of the directory. `python3 -m http.server` is the fastest way to prove this to yourself without any cloud dependency.

## Using it

```bash
helm repo add local-workshop http://localhost:8756
helm repo update
helm search repo local-workshop
helm install my-webapp local-workshop/webapp --version 0.1.0 --namespace helm-repo-test --create-namespace
```

This is the exact same `helm repo add`/`helm search repo`/`helm install repo/chart` flow you used with `bitnami` back in Module 1 — the only difference is who's hosting the index and packages.

## OCI registries — the modern alternative

Chart repositories (the `index.yaml`-plus-`.tgz` format above) predate a newer, increasingly preferred option: pushing charts to an **OCI registry** — the same kind of registry that stores container images (`helm push mychart.tgz oci://registry.example.com/charts`, `helm pull oci://...`). No `index.yaml` to maintain, and it reuses registry infrastructure/auth most teams already run for images. That's a Module 3 topic (see [03-advanced](../../03-advanced/)) — this lesson deliberately covers the classic repo format first, since it's what you'll still encounter constantly (`bitnami`, `ingress-nginx`, and most public charts still ship this way) and it's what OCI-based distribution evolved from.

## Exercise

Go to [exercise.md](exercise.md). No new `solution/` chart this time — this lesson is about repository mechanics, not template changes, so it reuses the finished chart from [Lesson 6](../06-linting-and-testing/solution/webapp-with-tests/).
