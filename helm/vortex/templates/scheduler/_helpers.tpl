{{/*
scheduler labels
*/}}
{{- define "vortex.scheduler.labels" -}}
app.kubernetes.io/app: scheduler
{{- end }}

{{/*
scheduler Selector labels
*/}}
{{- define "vortex.scheduler.selectorLabels" -}}
app.kubernetes.io/app: scheduler
{{- end }}

