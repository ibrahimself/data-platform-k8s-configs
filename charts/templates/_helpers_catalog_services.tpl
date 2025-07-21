
{{/**
Copyright (C) 2017-2019 Dremio Corporation. This file is confidential and private property.
**/}}

{{/*
Catalog Services - Dremio Catalog Services - App Name
*/}}
{{- define "dremio.catalogservices.app.name" -}}
dremio-catalog-services-server
{{- end -}}

{{/*
Catalog Services - Dremio Catalog Services - GRPC Port
*/}}
{{- define "dremio.catalogservices.ports.grpc" -}}
9000
{{- end -}}

{{/*
Catalog Services - Dremio Catalog Services - Management Port
*/}}
{{- define "dremio.catalogservices.ports.mgmt" -}}
9001
{{- end -}}

{{/*
Catalog Services - Dremio Catalog Services - JVM Options
*/}}
{{- define "dremio.catalogservices.java.options" -}}
{{- if $.Values.catalogservices.enabled -}}
-Dservices.dremiocatalog.services-uri={{ include "dremio.catalogservices.app.name" $ }}
-Dservices.dremiocatalog.services-port={{ include "dremio.catalogservices.ports.grpc" $ }}
{{- end -}}
{{- end -}}

{{/*
Catalog Services - Dremio Catalog Servies - Tolerations
*/}}
{{- define "dremio.catalogservices.tolerations" -}}
{{- $tolerations := coalesce $.Values.catalogservices.tolerations $.Values.tolerations -}}
{{- if $tolerations -}}
tolerations:
  {{- toYaml $tolerations | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Catalog Services - Dremio Catalog Services - Pod Annotations
*/}}
{{- define "dremio.catalogservices.podAnnotations" -}}
{{- $podAnnotations := coalesce $.Values.catalogservices.podAnnotations $.Values.podAnnotations -}}
{{- if $podAnnotations -}}
{{ toYaml $podAnnotations }}
{{- end -}}
{{- end -}}

{{/*
Catalog Services - Dremio Catalog Sevices - Pod Node Selectors
*/}}
{{- define "dremio.catalogservices.nodeSelector" -}}
{{- $catalogServiesNodeSelector := coalesce $.Values.catalogservices.nodeSelector $.Values.nodeSelector -}}
{{- if $catalogServiesNodeSelector -}}
nodeSelector:
  {{- toYaml $catalogServiesNodeSelector | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Catalog Services - Dremio Catalog Services - Annotations
*/}}
{{- define "dremio.catalogservices.annotations" -}}
{{- $annotations := coalesce $.Values.catalogservices.annotations $.Values.annotations -}}
{{- if $annotations -}}
annotations:
  {{- toYaml $annotations | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Catalog Services - Pod Labels
*/}}
{{- define "dremio.catalogservices.podLabels" -}}
{{- $podLabels := coalesce $.Values.catalogservices.podLabels $.Values.podLabels -}}
{{- if $podLabels -}}
{{ toYaml $podLabels }}
{{- end -}}
{{- end -}}
