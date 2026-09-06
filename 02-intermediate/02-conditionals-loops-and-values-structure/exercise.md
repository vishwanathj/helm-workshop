# Exercise 2 · Optional Env Vars, Resources & a NodePort Toggle

Continue in `/tmp/webapp` with the chart from Lesson 1.

## Part A — a `range` over environment variables

1. Add an empty, documented `env` list to `values.yaml`:
   ```yaml
   env: []
     # - name: APP_ENV
     #   value: "workshop"
   ```

2. In `templates/deployment.yaml`, generate an `env:` block from it, skipping entirely when the list is empty:
   ```yaml
           ports:
             - containerPort: 80
           {{- with .Values.env }}
           env:
             {{- range . }}
             - name: {{ .name }}
               value: {{ .value | quote }}
             {{- end }}
           {{- end }}
           volumeMounts:
   ```

3. Confirm the default render has no `env:` key at all:
   ```bash
   helm template webapp . | grep -A2 "containerPort: 80"
   ```

4. Now render with an override and confirm `env:` appears:
   ```bash
   helm template webapp . --set env[0].name=APP_ENV --set env[0].value=workshop
   ```

## Part B — pass-through `resources` with `toYaml`

5. Add an empty, documented `resources` block to `values.yaml`:
   ```yaml
   resources: {}
     # requests:
     #   cpu: 50m
     #   memory: 64Mi
     # limits:
     #   cpu: 100m
     #   memory: 128Mi
   ```

6. In `templates/deployment.yaml`, add this right after `volumeMounts:` (same indentation level as `image:`/`ports:`/`env:`, i.e. 10 spaces before `resources:`):
   ```yaml
           {{- with .Values.resources }}
           resources:
             {{- toYaml . | nindent 12 }}
           {{- end }}
   ```

7. Create a values file to exercise it:
   ```yaml
   # /tmp/webapp/custom-values-resources.yaml
   resources:
     requests:
       cpu: 50m
       memory: 64Mi
     limits:
       cpu: 100m
       memory: 128Mi
   ```
   Render and confirm the block appears verbatim, correctly indented under the `webapp` container:
   ```bash
   helm template webapp . -f custom-values-resources.yaml
   ```
   If the indentation is off, `resources:` will end up as a sibling of `containers:` instead of a field on the container — compare carefully against `image:`/`ports:` in the same output.

## Part C — a NodePort toggle

8. Add `nodePort: ""` under `service:` in `values.yaml`:
   ```yaml
   service:
     type: ClusterIP
     port: 80
     nodePort: ""
   ```

9. In `templates/service.yaml`, only emit `nodePort` when the service type is actually `NodePort` *and* a port was given:
   ```yaml
     ports:
       - port: {{ .Values.service.port }}
         targetPort: 80
         {{- if and (eq .Values.service.type "NodePort") .Values.service.nodePort }}
         nodePort: {{ .Values.service.nodePort }}
         {{- end }}
   ```

10. Confirm both branches:
    ```bash
    helm template webapp . | grep -A4 "ports:"
    helm template webapp . --set service.type=NodePort --set service.nodePort=30080 | grep -A5 "ports:"
    ```
    The first should have no `nodePort:` line; the second should.

11. Apply your custom-values file from Lesson 1/6 plus resources, then verify against the live cluster:
    ```bash
    helm upgrade webapp . --namespace helm-basics -f custom-values.yaml -f custom-values-resources.yaml
    kubectl get pod --namespace helm-basics -o jsonpath='{.items[0].spec.containers[0].resources}'
    ```

## Questions

<details>
<summary>Q1: In the <code>range</code> block, why is <code>.name</code> and <code>.value</code> used instead of <code>$.Values.env.name</code> or similar?</summary>

Inside a `range` block, `.` is rebound to the current item of the loop, not the root context — so on each iteration `.` is one entry of the `env` list, e.g. `{name: APP_ENV, value: workshop}`, and `.name`/`.value` read its fields directly. `$.Values` would still work to reach the *root* context from inside the loop (e.g. if you needed some other value alongside the loop variable), but `.Values.env` itself doesn't exist once you're inside the loop — there is no `.Values` anymore, only the current item.
</details>

<details>
<summary>Q2: What would happen if you used <code>if .Values.resources</code> instead of <code>with .Values.resources</code> in Part B?</summary>

It would still correctly skip the block when `resources` is empty (`{}` is falsy), but you'd have to write `.Values.resources` again inside the block (`{{- toYaml .Values.resources | nindent 12 }}`) since plain `if` doesn't change what `.` refers to. `with` does both jobs at once — it's the idiomatic choice specifically when you both want to guard on emptiness AND immediately use that same value inside.
</details>

<details>
<summary>Q3: Why guard the NodePort field with <em>both</em> <code>eq .Values.service.type "NodePort"</code> and <code>.Values.service.nodePort</code>, instead of just one?</summary>

Checking only the type would render `nodePort: ` with nothing after it if someone sets `service.type: NodePort` but leaves `nodePort` unset — invalid YAML, or at best a confusing empty field. Checking only `nodePort` would let someone accidentally set a `nodePort` value while `service.type` is still `ClusterIP`, which Kubernetes rejects outright (`ClusterIP` services can't have a `nodePort`). Requiring both means the field only ever appears in the one combination where it's actually valid.
</details>

Next: [Lesson 3 · Forcing Rollouts on Config Change](../03-forcing-rollouts-on-config-change/)
