{{/*
workspace labels
*/}}
{{- define "vortex.workspace.labels" -}}
app.kubernetes.io/app: workspace
{{- end }}

{{/*
workspace Selector labels
*/}}
{{- define "vortex.workspace.selectorLabels" -}}
app.kubernetes.io/app: workspace
{{- end }}

