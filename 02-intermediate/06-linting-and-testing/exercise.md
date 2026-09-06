# Exercise 6 · Strict Linting and a Real `helm test`

Continue in `/tmp/webapp` with the chart from Lesson 5 (including hooks and the `greeter` dependency).

## Part A — see `--strict` change the outcome

1. Temporarily edit `Chart.yaml` and set:
   ```yaml
   version: "0.1"
   ```
2. Run a plain lint and note the exit code:
   ```bash
   helm lint .
   echo "exit code: $?"
   ```
   You should see a `[WARNING]` about SemVer, but `0 chart(s) failed` and exit code `0`.
3. Now run it strict:
   ```bash
   helm lint . --strict
   echo "exit code: $?"
   ```
   Same warning, but now `1 chart(s) failed` and a non-zero exit code.
4. Revert `Chart.yaml` back to `version: "0.1.0"` and confirm both commands pass clean again.

## Part B — add a real connectivity test

5. Create `templates/tests/test-connection.yaml`:
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: {{ include "webapp.fullname" . }}-test-connection
     labels:
       {{- include "webapp.labels" . | nindent 4 }}
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

6. Validate and apply:
   ```bash
   helm lint .
   helm upgrade webapp . --namespace helm-basics -f custom-values.yaml
   ```

7. Run the test:
   ```bash
   helm test webapp --namespace helm-basics --logs
   ```
   You should see `PASSED` and, thanks to `--logs`, the actual HTML your `webapp` Service returned (your custom message from the ConfigMap, inside the `<h1>`).

## Part C — make it fail, on purpose

8. Temporarily point the test at the wrong port:
   ```yaml
         args: ["-q", "-O-", "http://{{ include "webapp.fullname" . }}:9999"]
   ```
9. Re-apply and re-test:
   ```bash
   helm upgrade webapp . --namespace helm-basics -f custom-values.yaml
   helm test webapp --namespace helm-basics --logs
   ```
   This should report `FAILED`, with a connection-refused error in the logs — the Service simply doesn't listen on `9999`. Give it a minute or two: `wget`'s own connection timeout means `helm test` can take 60-90 seconds to come back with the failure — it hasn't hung, it's waiting out `wget`'s retry/timeout behavior before giving up.
10. Revert the port back to `{{ .Values.service.port }}`, re-apply, and re-test to confirm it passes again.

## Questions

<details>
<summary>Q1: Would a broken <code>test-connection.yaml</code> block a <code>helm upgrade</code> the way a failing <code>pre-upgrade</code> hook did in Lesson 5?</summary>

No. `helm.sh/hook: test` only runs when you explicitly invoke `helm test` — it never runs automatically during `install`/`upgrade`. That's the key difference from `pre-`/`post-install`/`upgrade` hooks: tests are opt-in, on-demand checks against a release that's already been deployed, not gates in the deploy path itself. (A CI pipeline can of course choose to run `helm test` right after every `helm upgrade` and treat a failure as a pipeline failure — that's a Module 3 topic.)
</details>

<details>
<summary>Q2: Why does <code>--strict</code> matter more in CI than for your own local <code>helm lint</code> runs during this workshop?</summary>

Locally, you're reading the lint output yourself either way — a `WARNING` catches your eye whether or not the exit code reflects it. In CI, only the exit code matters: a pipeline step checks "did this command succeed," not "were there any warnings in the text output." Without `--strict`, a chart with real (if minor) problems can sail through CI indefinitely because nothing ever causes a non-zero exit.
</details>

Next: [Lesson 7 · Packaging & Hosting Your Own Chart Repository](../07-packaging-and-chart-repositories/)
