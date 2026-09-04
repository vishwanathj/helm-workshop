# Lesson 5 · Your First Chart

Time to build a chart from scratch instead of reading a generated one. You'll create a minimal chart called `webapp` that deploys an nginx container with a Kubernetes `Deployment` and `Service`, both configurable via `values.yaml`.

Keeping it minimal (no `_helpers.tpl`, no `NOTES.txt`, no tests) is deliberate — you'll see the essential moving parts without scaffolding noise. Lesson 6 layers templating and overrides on top of exactly this chart.

## What you're building

```
webapp/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    └── service.yaml
```

A `Deployment` running `nginx`, with `replicaCount`, `image.repository`, `image.tag`, `service.type`, and `service.port` all driven from `values.yaml` rather than hardcoded.

## A couple of conventions to follow as you write it

- **Chart names**: lowercase, hyphen-separated (`webapp`, not `WebApp` or `web_app`). Helm doesn't strictly enforce this, but it's the near-universal convention — mixed case or underscores will confuse other tooling and other people reading your chart.
- **Quote string values in YAML**, especially anything that could be misread as another type — e.g. `tag: "1.25"` rather than `tag: 1.25` (YAML would otherwise parse `1.25` as a number, not a string, which can break image references). Chart.yaml's `appVersion: "1.25"` is the same reasoning.
- **`apiVersion: v2` in `Chart.yaml`** means "this chart targets Helm 3+" (the current major line, including Helm 4, still uses `v2`). `apiVersion: v1` marks a chart written for the old, retired Helm 2.

## Exercise

Go to [exercise.md](exercise.md). A complete working chart is in [solution/webapp/](solution/webapp/) if you want to check your work or get unstuck — try building it yourself first.
