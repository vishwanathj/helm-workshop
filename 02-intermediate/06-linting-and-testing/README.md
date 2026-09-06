# Lesson 6 · `helm lint` and `helm test`

You've been running `helm lint` since Module 1 as a reflex before every install/upgrade. This lesson looks at what it actually checks, what `--strict` changes, and introduces `helm test` — a way to validate a *running* release, not just a chart's static structure.

## `helm lint` severity levels

Lint findings come in three levels: `INFO`, `WARNING`, and `ERROR`. Only `ERROR` fails a plain `helm lint` — the `1 chart(s) failed` you've been watching for. `WARNING`s print but don't fail the command by default. `--strict` changes that: it makes `WARNING`s fail the lint too.

For example, a chart version that isn't valid SemVer (`version: "0.1"` instead of `"0.1.0"`) is only a `WARNING`:

```
$ helm lint .
==> Linting .
[WARNING] Chart.yaml: version '0.1' is not a valid SemVerV2

1 chart(s) linted, 0 chart(s) failed
```

```
$ helm lint . --strict
==> Linting .
[WARNING] Chart.yaml: version '0.1' is not a valid SemVerV2

Error: 1 chart(s) linted, 1 chart(s) failed
```

Same input, different exit code. This is exactly the kind of thing worth enforcing in CI (Module 3) even though it's harmless for local workshop use — `--strict` is the difference between "someone might notice this warning" and "the pipeline stops here."

`helm lint` also accepts the same `--set`/`-f` flags as `install`/`upgrade`, so you can lint a chart against a *specific* values override, not just its defaults:

```bash
helm lint . -f custom-values.yaml --strict
```

## `helm test` — smoke-testing a live release

Lint only looks at the chart's static files — it never talks to a cluster and can't tell you whether the *deployed* application actually works. `helm test` closes that gap: it runs one or more Pods (or Jobs) annotated `helm.sh/hook: test` against an **already-installed** release, and reports pass/fail.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: {{ include "webapp.fullname" . }}-test-connection
  annotations:
    helm.sh/hook: test
spec:
  containers:
    - name: wget
      image: busybox:1.36
      command: ["wget"]
      args: ["-q", "-O-", "http://{{ include "webapp.fullname" . }}:{{ .Values.service.port }}"]
  restartPolicy: Never
```

By convention these live under `templates/tests/`. `wget -q -O-` requests the page and prints it to stdout, exiting non-zero if the request fails — exactly the signal a test Pod needs to report success or failure back to Helm.

```bash
helm test webapp --namespace helm-basics --logs
```

`--logs` prints the test Pod's container logs inline, which is almost always what you want — without it you'd have to go find and `kubectl logs` the Pod yourself. Test hooks share the same annotations as other hooks (`helm.sh/hook-weight` to order multiple tests, `helm.sh/hook-delete-policy` to control cleanup), but use the dedicated `helm test` hook point, not `pre-`/`post-install`.

## Exercise

Go to [exercise.md](exercise.md). A complete working chart is in [solution/webapp-with-tests/](solution/webapp-with-tests/).
