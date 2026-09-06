# Lesson 2 · Conditionals, Loops & Structuring `values.yaml`

Real charts don't just substitute scalars into fields — they optionally include whole blocks, and they generate repeated blocks from a list. This lesson covers the three template constructs that make that possible, plus how to structure `values.yaml` so those constructs have something sensible to work with.

## `if` / `else` — optional blocks

```
{{- if eq .Values.service.type "NodePort" }}
nodePort: {{ .Values.service.nodePort }}
{{- end }}
```

Common comparison/boolean functions: `eq`, `ne`, `and`, `or`, `not`. Go templates treat the zero value of a type as "false" in a boolean context — an empty string `""`, `0`, `nil`, `false`, and an empty list/map all count as falsy. That's why `.Values.service.nodePort: ""` (empty string, the "unset" default) safely evaluates as false without needing an explicit `ne .Values.service.nodePort ""` check.

## `with` — scope into a value, and skip the block if it's empty

```
{{- with .Values.resources }}
resources:
  {{- toYaml . | nindent 12 }}
{{- end }}
```

`with X` re-points `.` to `X` for the rest of the block, **and** skips the block entirely if `X` is empty/nil — it's an `if` and a scope change in one. Inside the block, `.` no longer refers to the root context, which is the most common `with` mistake: if you need `.Values` or `.Release` again inside a `with` block, use `$.Values`/`$.Release` (`$` always refers to the root context, no matter how deeply you're nested).

## `range` — loop over a list or map

```
{{- range .Values.env }}
- name: {{ .name }}
  value: {{ .value | quote }}
{{- end }}
```

Same scoping rule as `with`: inside `range`, `.` is the current list item, not the root context. Use `$` to reach back to the root if needed inside the loop body.

## `toYaml` — pass a whole values sub-tree through untouched

For anything shaped like real Kubernetes YAML that you don't want to reinvent field-by-field in a template (`resources`, `nodeSelector`, `tolerations`, `affinity` are the classic examples), let the chart consumer write real YAML in `values.yaml` and pass it straight through:

```
{{- with .Values.resources }}
resources:
  {{- toYaml . | nindent 12 }}
{{- end }}
```

`nindent N` is `indent N` plus a leading newline — almost always what you want when inserting a multi-line block under a YAML key. Get the indent number wrong and you'll get invalid YAML or, worse, a value nested under the wrong key; when in doubt, render with `helm template` and count spaces against a sibling key.

## Structuring `values.yaml` as it grows

- Group related settings under a nested key (`service.type`, `service.port`, `service.nodePort`) rather than flat top-level keys — it mirrors how you'll reference them in templates (`.Values.service.type`) and reads better as the file grows.
- For anything optional, default to an empty value that's falsy in Go templates: `{}` for a map, `[]` for a list, `""` for a string. Then gate the whole block with `with` or `if` so "unset" reliably means "omitted," not "rendered with empty/zero garbage."
- Comment out an example usage next to an empty default (see this lesson's `values.yaml`) so a chart consumer can see the expected shape without reading the templates.

## Exercise

Go to [exercise.md](exercise.md). A complete working chart is in [solution/webapp-with-conditionals/](solution/webapp-with-conditionals/).
