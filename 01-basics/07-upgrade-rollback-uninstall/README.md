# Lesson 7 · Upgrade, Rollback & Uninstall

Every `helm upgrade` creates a new numbered **revision** of a release. Helm keeps this history, which is what makes rollback possible — it's not magic, it's just re-applying a previous revision's rendered manifests.

## Core commands

| Command | What it does |
|---|---|
| `helm upgrade <release> <chart>` | Applies a new configuration/chart version to an existing release, creating a new revision |
| `helm history <release>` | Lists all revisions of a release, with status |
| `helm rollback <release> <revision>` | Reverts a release to a previous revision |
| `helm uninstall <release>` | Deletes a release and all its Kubernetes resources |
| `helm upgrade --install` | Installs the release if it doesn't exist yet, upgrades it if it does — handy for idempotent scripts/CI |
| `helm upgrade --rollback-on-failure` | If the upgrade fails, automatically rolls back to the previous working revision (older Helm versions call this `--atomic` — same behavior, `--atomic` is now a deprecated alias) |

## Why this matters

Rollback is the safety net that makes Helm trustworthy for real deployments. If an upgrade goes wrong — bad image tag, broken config — you're one command away from the last known-good state, without having to manually reconstruct what changed.

## Exercise

Go to [exercise.md](exercise.md). You'll intentionally break your `webapp` release, then recover it.
