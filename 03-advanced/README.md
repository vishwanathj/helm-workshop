# Module 3 · Advanced

By the end of this module you'll be able to distribute charts via OCI registries, sign and verify them, factor shared logic into a library chart, write your own Helm plugin, manage multiple releases declaratively with Helmfile, gate changes on automated chart tests, and run a real GitOps loop with Argo CD.

Make sure you've completed [Module 2 · Intermediate](../02-intermediate/) first.

## Lessons

1. [OCI Registries](01-oci-registries/) — `helm push`/`pull oci://`, the modern alternative to classic chart repos
2. [Chart Provenance & Signing](02-chart-provenance-and-signing/) — `helm package --sign`, `helm verify`, GPG
3. [Library Charts](03-library-charts/) — factoring `_helpers.tpl` out into a reusable, dependency-only chart
4. [Custom Helm Plugins](04-custom-helm-plugins/) — writing and installing your own `helm` subcommand
5. [Helmfile](05-helmfile/) — declaratively managing multiple releases from one file
6. [Chart Testing & CI](06-chart-testing-and-ci/) — `ct lint`/`ct install`, and a GitHub Actions workflow
7. [GitOps with Argo CD](07-gitops-with-argocd/) — sync, drift, and self-heal against a real git repo

Work through them in order — each one assumes you completed the last.
