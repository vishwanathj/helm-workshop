{{/*
Base name for resources, derived from the chart name.
*/}}
{{- define "webapp.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Fully qualified resource name: "<release>-<chart>", or just <release> when
the release name already contains the chart name (so "helm install webapp ."
gives you plain "webapp" instead of "webapp-webapp").
*/}}
{{- define "webapp.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "webapp.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Common, decorative labels. Deliberately NOT used for any selector: a
Deployment's spec.selector.matchLabels is immutable after creation, so if a
label used for selection ever needs to change, "helm upgrade" fails outright
on an existing release. The "app: webapp" label in deployment.yaml/
service.yaml is left as a plain hand-written literal for exactly that
reason — see the exercise for what happens if you break this rule.
*/}}
{{- define "webapp.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/name: {{ include "webapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
