{{/*
Engine labels
*/}}
{{- define "vortex.engine.labels" -}}
app.kubernetes.io/app: engine
{{- end }}

{{/*
Engine Selector labels
*/}}
{{- define "vortex.engine.selectorLabels" -}}
app.kubernetes.io/app: engine
{{- end }}

