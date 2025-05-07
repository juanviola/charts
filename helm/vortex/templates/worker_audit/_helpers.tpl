{{/*
workerAudit labels
*/}}
{{- define "vortex.workerAudit.labels" -}}
app.kubernetes.io/app: worker-audit
{{- end }}

{{/*
workerAudit Selector labels
*/}}
{{- define "vortex.workerAudit.selectorLabels" -}}
app.kubernetes.io/app: worker-audit
{{- end }}

