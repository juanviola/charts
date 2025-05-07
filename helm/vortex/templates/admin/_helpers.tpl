{{/*
admin labels
*/}}
{{- define "vortex.admin.labels" -}}
app.kubernetes.io/app: admin
{{- end }}

{{/*
admin Selector labels
*/}}
{{- define "vortex.admin.selectorLabels" -}}
app.kubernetes.io/app: admin
{{- end }}

