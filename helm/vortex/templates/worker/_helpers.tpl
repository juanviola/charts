{{/*
worker labels
*/}}
{{- define "vortex.worker.labels" -}}
app.kubernetes.io/app: worker
{{- end }}

{{/*
worker Selector labels
*/}}
{{- define "vortex.worker.selectorLabels" -}}
app.kubernetes.io/app: worker
{{- end }}

