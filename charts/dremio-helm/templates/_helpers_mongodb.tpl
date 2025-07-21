{{/**
Copyright (C) 2017-2019 Dremio Corporation. This file is confidential and private property.
**/}}

{{/*
MongoDB - Cluster Name
*/}}
{{- define "dremio.mongodb.cluster" -}}
{{ .Release.Name }}-mongodb
{{- end -}}

{{/*
MongoDB - Database Name
*/}}
{{- define "dremio.mongodb.db" -}}
dremio
{{- end -}}

{{/*
MongoDB - User Name
*/}}
{{- define "dremio.mongodb.user" -}}
dremio
{{- end -}}

{{/*
MongoDB - User Secret Name
*/}}
{{- define "dremio.mongodb.userSecret" -}}
{{ include "dremio.mongodb.cluster" . }}-app-users
{{- end -}}

{{/*
MongoDB - Connection String
*/}}
{{- define "dremio.mongodb.connectionString" -}}
mongodb+srv://{{ include "dremio.mongodb.cluster" . }}-rs0.{{ .Release.Namespace }}.svc.cluster.local/{{ include "dremio.mongodb.db" . }}?ssl=false
{{- end -}}

{{/*
MongoDB - Wait for MongoDB Init Container
Note: a Volume named "temp-dir" must be declared in the parent Pod template.
Note: this template is tailored for Bitnami MongoDB Helm Chart.
*/}}
{{- define "dremio.mongodb.waitForMongoInitContainer" -}}
- name: wait-for-mongo
  image: {{ $.Values.mongodb.image.repository }}:{{ $.Values.mongodb.image.tag }}
  imagePullPolicy: {{ $.Values.mongodb.image.pullPolicy }}
  env:
    - name: MONGODB_USERNAME
      value: "{{ include "dremio.mongodb.user" $ }}"
    - name: MONGODB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: "{{ include "dremio.mongodb.userSecret" $ }}"
          key: "{{ include "dremio.mongodb.user" $ }}"
    - name: MONGODB_CONNECTION_STRING
      value: "{{ include "dremio.mongodb.connectionString" $ }}"
  command:
    - "sh"
    - "-c"
    - |
      while : ; do
        echo "Waiting for MongoDB connectivity..."
        if mongosh --quiet "$(MONGODB_CONNECTION_STRING)" --username "$(MONGODB_USERNAME)" --password "$(MONGODB_PASSWORD)" \
         --eval '
          disableTelemetry()
          let hello = db.hello()
          if ((hello.isWritablePrimary || hello.secondary) && hello.hosts.length > {{ if .Values.devMode -}}0{{- else -}}2{{- end }}) {
            print("MongoDB service looks ready")
          } else {
            throw new Error("MongoDB service not ready, retrying in 5 seconds...")
          }'; then
          break
        fi
        sleep 5
      done
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop:
      - ALL
    privileged: false
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    runAsGroup: 65534
    runAsUser: 65534
  resources:
    limits:
      cpu: 100m
      memory: 200Mi
    requests:
      cpu: 100m
      memory: 200Mi
  volumeMounts:
    - name: temp-dir
      mountPath: /.mongodb
{{- end -}}

{{/*
MongoDB - Metrics Port - Internal
*/}}
{{- define "dremio.mongodb.ports.metrics.internal" -}}
9216
{{- end -}}

{{/*
MongoDB - Tolerations
*/}}
{{- define "dremio.mongodb.tolerations" -}}
{{- $tolerations := coalesce $.Values.mongodb.tolerations $.Values.tolerations -}}
{{- if $tolerations -}}
tolerations:
  {{- toYaml $tolerations | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
MongoDB - Pod Annotations
*/}}
{{- define "dremio.mongodb.podAnnotations" -}}
{{- $podAnnotations := coalesce $.Values.mongodb.annotations $.Values.podAnnotations -}}
{{- if $podAnnotations -}}
{{ toYaml $podAnnotations }}
{{- end -}}
{{- end -}}

{{/*
MongoDB - Pod Node Selectors
*/}}
{{- define "dremio.mongodb.nodeSelector" -}}
{{- $mongoNodeSelector := coalesce $.Values.mongodb.nodeSelector $.Values.nodeSelector -}}
{{- if $mongoNodeSelector -}}
nodeSelector:
  {{- toYaml $mongoNodeSelector | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
MongoDB - Annotations
*/}}
{{- define "dremio.mongodb.annotations" -}}
{{- $annotations := coalesce $.Values.mongodb.annotations $.Values.annotations -}}
{{- if $annotations -}}
annotations:
  {{- toYaml $annotations | nindent 2 }}
{{- end -}}
{{- end -}}


{{/*
MongoDB - Pod Labels
*/}}
{{- define "dremio.mongodb.podLabels" -}}
{{- $podLabels := coalesce $.Values.mongodb.labels $.Values.podLabels -}}
{{- if $podLabels -}}
labels:
  {{- toYaml $podLabels | nindent 2 }}
{{- end -}}
{{- end -}}

