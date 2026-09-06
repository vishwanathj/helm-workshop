# Exercise 3 · Make ConfigMap Changes Roll Out Immediately

Continue in `/tmp/webapp` with the chart from Lesson 2.

## Part A — reproduce the delay (skip if you already saw this in Module 1)

1. Change the message in `values.yaml`:
   ```yaml
   html:
     message: "Checksum test, take one"
   ```
2. Upgrade and immediately check the page:
   ```bash
   helm upgrade webapp . --namespace helm-basics -f custom-values.yaml
   kubectl port-forward --namespace helm-basics svc/webapp 8080:80 &
   curl localhost:8080
   ```
   You'll likely still see the *previous* message — the ConfigMap changed, but the running pod hasn't re-synced its mounted view of it yet, and even once it does, nginx doesn't reload the file on its own without a restart. Stop the port-forward (`kill %1` or `Ctrl+C` in its terminal) before continuing.

## Part B — add the checksum annotation

3. In `templates/deployment.yaml`, add an `annotations:` block under `spec.template.metadata`, as a sibling of `labels:`:
   ```yaml
     template:
       metadata:
         labels:
           app: webapp
           {{- include "webapp.labels" . | nindent 8 }}
         annotations:
           checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
   ```

4. Confirm the checksum actually changes with content, using `helm template` (no cluster needed):
   ```bash
   helm template webapp . | grep "checksum/config"
   helm template webapp . --set html.message="something else" | grep "checksum/config"
   ```
   The two hashes should differ. Now confirm it's *stable* when nothing relevant changes — run the first command twice in a row and diff the output; the hash should be identical both times.

## Part C — prove the rollout is now immediate

5. Change the message again:
   ```yaml
   html:
     message: "Checksum test, take two"
   ```
6. Before upgrading, note the current pod name(s) and their age:
   ```bash
   kubectl get pods --namespace helm-basics -o wide
   ```
7. Upgrade:
   ```bash
   helm upgrade webapp . --namespace helm-basics -f custom-values.yaml
   ```
8. Immediately check pods again:
   ```bash
   kubectl get pods --namespace helm-basics -o wide
   ```
   You should see brand-new pod name(s) with an age of just a few seconds — a real rollout happened right away, not after a 30-60s delay.
9. Confirm the new content is live:
   ```bash
   kubectl port-forward --namespace helm-basics svc/webapp 8080:80 &
   curl localhost:8080
   kill %1
   ```
   You should immediately see "Checksum test, take two" — no waiting this time.

## Questions

<details>
<summary>Q1: If you changed <code>replicaCount</code> instead of <code>html.message</code>, would the checksum annotation's value change?</summary>

No. The checksum is computed only from the *rendered content of `configmap.yaml`*, which doesn't reference `.Values.replicaCount` at all. Changing `replicaCount` would still trigger its own rollout (it's a separate field under `spec` that Kubernetes always reconciles), but the checksum annotation specifically would stay exactly the same, because the ConfigMap's content didn't change.
</details>

<details>
<summary>Q2: What's a downside of this pattern if a chart has many ConfigMaps and Secrets mounted by one Deployment?</summary>

Each one needs its own checksum annotation (or you hash all of them together into one annotation), and every one of them adds a line of boilerplate to every Deployment template in the chart. It works well at small scale but becomes repetitive — some charts factor the checksum computation into a shared named template in `_helpers.tpl` to cut down the duplication once there are several files to watch.
</details>

Next: [Lesson 4 · Chart Dependencies & Subcharts](../04-chart-dependencies-and-subcharts/)
