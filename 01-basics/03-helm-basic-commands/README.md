# Lesson 3 · Helm Basic Commands

Before building your own chart, install someone else's — this is what most Helm usage actually looks like day-to-day.

## Core commands

| Command | What it does |
|---|---|
| `helm repo add <name> <url>` | Registers a chart repository locally |
| `helm repo update` | Refreshes the local cache of available charts from added repos |
| `helm search repo <keyword>` | Searches chart repos you've added |
| `helm show values <chart>` | Prints the default `values.yaml` for a chart, so you know what's configurable |
| `helm install <release-name> <chart>` | Installs a chart as a new release |
| `helm list` (or `helm ls`) | Lists releases in the current namespace |
| `helm status <release-name>` | Shows details/status of a release |
| `helm get values <release-name>` | Shows the values a release was installed with |
| `helm uninstall <release-name>` | Removes a release and its resources |

A **release name** is yours to choose — it's just a label for this particular installation (e.g., `my-nginx`). It's not the chart's name.

## Exercise

Go to [exercise.md](exercise.md).
