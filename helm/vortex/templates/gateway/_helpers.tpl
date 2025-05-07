{{/*
gateway labels
*/}}
{{- define "vortex.gateway.labels" -}}
app.kubernetes.io/app: gateway
{{- end }}

{{/*
gateway Selector labels
*/}}
{{- define "vortex.gateway.selectorLabels" -}}
app.kubernetes.io/app: gateway
{{- end }}

