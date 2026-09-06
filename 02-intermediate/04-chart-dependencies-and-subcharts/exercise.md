# Exercise 4 · Add a `greeter` Subchart to `webapp`

## Part A — build the standalone `greeter` chart

1. Create it as a **sibling** of `/tmp/webapp` (this matters — the dependency path in Part B is relative):
   ```bash
   mkdir -p /tmp/greeter/templates
   ```

2. `/tmp/greeter/Chart.yaml`:
   ```yaml
   apiVersion: v2
   name: greeter
   description: A tiny standalone chart used to demonstrate Helm chart dependencies
   version: 0.1.0
   appVersion: "1.0.0"
   ```

3. `/tmp/greeter/values.yaml`. Declare `global.environment` here too, defaulted to empty — a subchart rendered on its own (nothing sets `global` for it) needs *something* under `global` in its own values, or referencing `.Values.global.environment` errors with a nil-pointer template error instead of just being empty:
   ```yaml
   message: "Hello from the greeter subchart!"

   global:
     environment: ""
   ```

4. `/tmp/greeter/templates/configmap.yaml`:
   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: {{ .Release.Name }}-greeter
   data:
     greeting: {{ .Values.message | quote }}
     environment: {{ .Values.global.environment | default "unspecified" | quote }}
   ```

5. Confirm it works completely on its own, with no relation to `webapp` yet:
   ```bash
   cd /tmp/greeter
   helm lint .
   helm template standalone .
   ```
   You should see `environment: "unspecified"` — nothing has set `global.environment` yet.

## Part B — declare it as a dependency of `webapp`

6. In `/tmp/webapp/Chart.yaml`, add:
   ```yaml
   dependencies:
     - name: greeter
       version: "0.1.0"
       repository: "file://../greeter"
       condition: greeter.enabled
   ```

7. In `/tmp/webapp/values.yaml`, add:
   ```yaml
   global:
     environment: "workshop"

   greeter:
     enabled: true
     message: "Hello from the greeter subchart, configured by the parent chart!"
   ```

8. Fetch the dependency:
   ```bash
   cd /tmp/webapp
   helm dependency update .
   ```
   Check what it did:
   ```bash
   ls charts/
   cat Chart.lock
   ```
   You should see `charts/greeter-0.1.0.tgz` and a `Chart.lock` recording the resolved version.

9. Render and confirm both the `greeter` ConfigMap and `webapp`'s own resources come out of one `helm template` call:
   ```bash
   helm template webapp . | grep -B2 -A5 "greeter"
   ```
   Confirm `greeting` shows your parent-supplied message, and `environment` now shows `"workshop"` (from `global.environment`) instead of `"unspecified"`.

10. List the resolved dependency and its status:
    ```bash
    helm dependency list .
    ```

## Part C — toggle it off with `condition`

11. Render with the subchart disabled and confirm nothing greeter-related appears:
    ```bash
    helm template webapp . --set greeter.enabled=false | grep -c greeter
    ```
    Should print `0`.

## Part D — install it for real

12. Upgrade your live release — this now manages three resources (`Deployment`, `Service`, and the subchart's `ConfigMap`) under one release:
    ```bash
    helm upgrade webapp . --namespace helm-basics -f custom-values.yaml
    kubectl get configmap --namespace helm-basics
    ```
    You should see both `webapp-html` and `webapp-greeter`.
13. Check the release's full resource list and confirm the subchart's `ConfigMap` is tracked as part of the same release (not a separate one):
    ```bash
    helm get manifest webapp --namespace helm-basics | grep "kind:"
    ```

## Questions

<details>
<summary>Q1: Why does <code>/tmp/greeter/templates/configmap.yaml</code> use plain <code>.Values.message</code> rather than something like <code>.Values.greeter.message</code>?</summary>

Because a subchart's templates are evaluated in their own values scope — Helm strips the `greeter:` prefix before handing values down to the subchart, so inside `greeter`'s own templates, what the parent wrote as `greeter.message` simply shows up as `.Values.message`. The subchart has no idea it's being used as a dependency of `webapp` at all; it's fully self-contained, which is exactly what let you `helm template`/`helm lint` it standalone in Part A.
</details>

<details>
<summary>Q2: What's the difference between <code>helm dependency update</code> and <code>helm dependency build</code>?</summary>

`update` re-resolves the version ranges in `Chart.yaml` against the repositories, potentially picking up newer versions, and rewrites `Chart.lock` to match what it found. `build` does not re-resolve anything — it reads the *existing* `Chart.lock` and fetches exactly those pinned versions into `charts/`. Use `build` in CI/reproducible-install contexts where you want the exact locked versions every time, and `update` when you deliberately want to pick up new dependency versions and refresh the lock.
</details>

<details>
<summary>Q3: What would happen if <code>greeter</code>'s <code>Chart.yaml</code> also declared its own <code>global.environment</code> default in its <code>values.yaml</code>?</summary>

The parent's `global` values always win over a subchart's own defaults for the same global key — that's the whole point of `global`, it flows one direction (root values down into every subchart), overriding what the subchart would otherwise use on its own. If the parent never sets `global.environment` at all, the subchart's own default (if any) would apply, same as any other value.
</details>

Next: [Lesson 5 · Helm Hooks](../05-helm-hooks/)
