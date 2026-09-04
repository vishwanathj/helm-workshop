# Lesson 1 · What is Helm?

## The problem

A real application on Kubernetes is rarely one file. A typical app might need a `Deployment`, a `Service`, a `ConfigMap`, an `Ingress`, and a `Secret` — five-plus YAML files, each slightly different per environment (dev vs. staging vs. prod: different replica counts, image tags, resource limits...).

Managing that by hand means copy-pasting YAML and manually swapping values every time you deploy. It doesn't scale and it's easy to get wrong.

## What Helm is

Helm is **the package manager for Kubernetes** — the same idea as `apt` for Ubuntu, `brew` for macOS, or `npm` for Node. It gives you:

- **Charts** — a packaged bundle of Kubernetes YAML templates plus a set of configurable values. Think of a chart as the "installable package" (like a `.deb` or a Homebrew formula).
- **Releases** — a specific instance of a chart installed into your cluster with a specific configuration. You can install the same chart multiple times under different release names (e.g., two independent Redis releases).
- **Repositories** — a place charts are published to and discovered from (similar to a package registry). [Artifact Hub](https://artifacthub.io/) is the public directory of Helm chart repositories.
- **Values** — the configuration knobs for a chart (replica count, image tag, resource limits, etc.) that let one chart be reused across many environments without editing its internals.

## The mental model

```
Chart (template)  +  Values (your config)  --helm install-->  Release (running in your cluster)
```

You write (or download) a chart once. You install it many times, in many places, with different values, as different releases.

## Why this matters day-to-day

- **Reuse**: install the same well-tested chart (e.g., PostgreSQL, Redis, nginx-ingress) instead of hand-writing YAML for common software.
- **Versioning**: every install is a tracked "release" with history — you can upgrade and roll back.
- **Templating**: one set of YAML templates + different values files = consistent deploys across dev/staging/prod.

## Check your understanding

<details>
<summary>Q1: What's the difference between a chart and a release?</summary>

A chart is the packaged template (the reusable definition). A release is a specific running instance of that chart in your cluster, created with `helm install`. You can have multiple releases from the same chart.
</details>

<details>
<summary>Q2: If Helm is like a package manager, what's the equivalent of a package repository?</summary>

A Helm chart repository (e.g., a repo added via `helm repo add`, browsable on Artifact Hub) — the equivalent of an apt/npm registry.
</details>

Next: [Lesson 2 · Install & Setup](../02-install-and-setup/)
