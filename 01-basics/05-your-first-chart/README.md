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

## Exercise

Go to [exercise.md](exercise.md). A complete working chart is in [solution/webapp/](solution/webapp/) if you want to check your work or get unstuck — try building it yourself first.
