# Module 2 · Intermediate

By the end of this module you'll be able to factor out reusable template logic, structure a growing `values.yaml`, force rollouts when config changes, compose charts out of subcharts, gate deploys on hooks, validate charts in CI-friendly ways, and distribute your own charts via a repository.

Make sure you've completed [Module 1 · Basics](../01-basics/) first — every lesson here continues building on the `webapp` chart from that module.

## Lessons

1. [Named Templates & `_helpers.tpl` in Depth](01-named-templates-and-helpers/) — `define`/`include`, the `name`/`fullname`/`labels` convention, why selector labels are special
2. [Conditionals, Loops & Structuring `values.yaml`](02-conditionals-loops-and-values-structure/) — `if`/`with`/`range`, `toYaml`, growing `values.yaml` cleanly
3. [Forcing Rollouts on Config Change](03-forcing-rollouts-on-config-change/) — the checksum annotation pattern
4. [Chart Dependencies & Subcharts](04-chart-dependencies-and-subcharts/) — `charts/`, `helm dependency update`, `global` values, `condition`
5. [Helm Hooks](05-helm-hooks/) — `pre-`/`post-install`/`upgrade`, weights, delete policies
6. [`helm lint` and `helm test`](06-linting-and-testing/) — `--strict`, and smoke-testing a live release
7. [Packaging & Hosting Your Own Chart Repository](07-packaging-and-chart-repositories/) — `helm package`, `helm repo index`, OCI as the modern alternative

Work through them in order — each one assumes you completed the last.
