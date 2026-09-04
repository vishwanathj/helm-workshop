# Lesson 6 · Values & Templates

The whole point of `values.yaml` is that you can reconfigure a chart without touching its templates. Helm gives you two ways to override values at install/upgrade time, and they can be combined.

## Ways to override values

1. **`--set key=value`** — quick, inline overrides on the command line. Good for one-off changes.
   ```bash
   helm upgrade webapp . --set replicaCount=3
   ```
   Nested keys use dots: `--set image.tag=1.27`. Multiple: `--set replicaCount=3,image.tag=1.27`.

2. **`-f custom-values.yaml`** — a values file with just the overrides you want, merged on top of the chart's default `values.yaml`. Preferred for anything more than a couple of fields, and for keeping a record of what an environment's config actually is.
   ```bash
   helm upgrade webapp . -f custom-values.yaml
   ```

If both are used, `--set` wins over `-f` (last one specified on the command line wins in general; `--set` is applied after `-f` files by default). In practice, pick one approach per change to avoid confusion.

## Previewing before you apply

Always preview before changing a live release:

```bash
helm upgrade webapp . -f custom-values.yaml --dry-run --debug
```

`--dry-run` renders and validates against the cluster but applies nothing. `--debug` prints the computed values and full rendered manifests, so you can see exactly what would change.

## Exercise

Go to [exercise.md](exercise.md). This lesson builds directly on the `webapp` release from Lesson 5 — make sure it's still installed (`helm list --namespace helm-basics`).
