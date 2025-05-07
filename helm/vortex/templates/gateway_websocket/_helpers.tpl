{{/*
gatewayWebSocket labels
*/}}
{{- define "vortex.gatewayWebSocket.labels" -}}
app.kubernetes.io/app: gateway-websocket
{{- end }}

{{/*
gatewayWebSocket Selector labels
*/}}
{{- define "vortex.gatewayWebSocket.selectorLabels" -}}
app.kubernetes.io/app: gateway-websocket
{{- end }}

