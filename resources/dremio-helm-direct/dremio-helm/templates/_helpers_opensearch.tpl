{{/**
Copyright (C) 2017-2019 Dremio Corporation. This file is confidential and private property.
**/}}

{{/*
Opensearch - PreInstall Job Pod Node Selectors
*/}}
{{- define "dremio.opensearch.preInstallJob.nodeSelector" -}}
{{- $opensearchNodeSelector := coalesce $.Values.opensearch.preInstallJob.nodeSelector $.Values.opensearch.nodeSelector $.Values.nodeSelector -}}
{{- if $opensearchNodeSelector -}}
nodeSelector:
  {{- toYaml $opensearchNodeSelector | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Opensearch - PreInstall Job Pod Tolerations
*/}}
{{- define "dremio.opensearch.preInstallJob.tolerations" -}}
{{- $tolerations := coalesce $.Values.opensearch.preInstallJob.tolerations $.Values.opensearch.tolerations $.Values.tolerations -}}
{{- if $tolerations -}}
tolerations:
  {{- toYaml $tolerations | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Opensearch -  OIDC Pod Node Selectors
*/}}
{{- define "dremio.opensearch.oidcProxy.nodeSelector" -}}
{{- $opensearchNodeSelector := coalesce $.Values.opensearch.oidcProxy.nodeSelector $.Values.opensearch.nodeSelector $.Values.nodeSelector -}}
{{- if $opensearchNodeSelector -}}
nodeSelector:
  {{- toYaml $opensearchNodeSelector | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Opensearch - OIDC Pod Tolerations
*/}}
{{- define "dremio.opensearch.oidcProxy.tolerations" -}}
{{- $tolerations := coalesce $.Values.opensearch.oidcProxy.tolerations $.Values.opensearch.tolerations $.Values.tolerations -}}
{{- if $tolerations -}}
tolerations:
  {{- toYaml $tolerations | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Opensearch - OIDC Pod Labels
*/}}
{{- define "dremio.opensearch.oidcProxy.podLabels" -}}
{{- $podLabels := coalesce $.Values.opensearch.oidcProxy.podLabels $.Values.podLabels -}}
{{- if $podLabels -}}
{{ toYaml $podLabels }}
{{- end -}}
{{- end -}}

{{/*
Opensearch - Tolerations
*/}}
{{- define "dremio.opensearch.tolerations" -}}
{{- $tolerations := coalesce $.Values.opensearch.tolerations $.Values.tolerations -}}
{{- if $tolerations -}}
tolerations:
  {{- toYaml $tolerations | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Opensearch - Pod Node Selectors
*/}}
{{- define "dremio.opensearch.nodeSelector" -}}
{{- $opensearchNodeSelector := coalesce $.Values.opensearch.nodeSelector $.Values.nodeSelector -}}
{{- if $opensearchNodeSelector -}}
nodeSelector:
  {{- toYaml $opensearchNodeSelector | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Opensearch - Labels
*/}}
{{- define "dremio.opensearch.podLabels" -}}
{{- $labels := coalesce $.Values.opensearch.podLabels $.Values.podLabels -}}
{{- if $labels -}}
labels:
  {{- toYaml $labels | nindent 2 }}
{{- end -}}
{{- end -}}
