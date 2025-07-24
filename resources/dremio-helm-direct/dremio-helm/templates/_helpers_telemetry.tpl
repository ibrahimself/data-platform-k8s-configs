{{/**
Copyright (C) 2017-2019 Dremio Corporation. This file is confidential and private property.
**/}}

{{/*
Telemetry - Pod Annotations
*/}}
{{- define "dremio.telemetry.podAnnotations" -}}
{{- $podAnnotations := coalesce $.Values.telemetry.podAnnotations $.Values.podAnnotations -}}
{{- if $podAnnotations -}}
{{ toYaml $podAnnotations }}
{{- end -}}
{{- end -}}

{{/*
Telemetry - Pod Node Selectors
*/}}
{{- define "dremio.telemetry.nodeSelector" -}}
{{- $telemetryNodeSelector := coalesce $.Values.telemetry.nodeSelector $.Values.nodeSelector -}}
{{- if $telemetryNodeSelector -}}
nodeSelector:
  {{- toYaml $telemetryNodeSelector | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Telemetry - Tolerations
*/}}
{{- define "dremio.telemetry.tolerations" -}}
{{- $tolerations := coalesce $.Values.telemetry.tolerations $.Values.tolerations -}}
{{- if $tolerations -}}
tolerations:
  {{- toYaml $tolerations | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Telemetry - Annotations
*/}}
{{- define "dremio.telemetry.annotations" -}}
{{- $annotations := coalesce $.Values.telemetry.annotations $.Values.annotations -}}
{{- if $annotations -}}
annotations:
  {{- toYaml $annotations | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Telemetry - Pod Labels
*/}}
{{- define "dremio.telemetry.podLabels" -}}
{{- $podLabels := coalesce $.Values.telemetry.podLabels $.Values.podLabels -}}
{{- if $podLabels -}}
{{ toYaml $podLabels }}
{{- end -}}
{{- end -}}
