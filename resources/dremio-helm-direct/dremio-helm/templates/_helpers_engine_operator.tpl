{{/*
Engines - Coordinator Container Extra Environment Variables
*/}}
{{- define "dremio.coordinator.engine.envs" -}}
- name: "KUBERNETES_NAMESPACE"
  value: {{ .Release.Namespace }}
{{- end -}}

{{/*
Engines - Coordinator Extra Volumes
*/}}
{{- define "dremio.coordinator.engine.volumes" -}}
- name: dremio-engine-config
  configMap:
    name: engine-options
{{- end -}}

{{/*
Engines - Coordinator Container Extra Volume Mounts
*/}}
{{- define "dremio.coordinator.engine.volume.mounts" -}}
- name: dremio-engine-config
  mountPath: /opt/dremio/conf/engine
{{- end -}}

{{/*
Engine Operator - Service Account
*/}}
{{- define "dremio.engine.operator.serviceAccount" -}}
{{- $operatorServiceAccount := coalesce (($.Values.engine).operator).serviceAccount "engine-operator" -}}
{{- if $operatorServiceAccount -}}
serviceAccountName: {{ $operatorServiceAccount }}
{{- end -}}
{{- end -}}

{{/*
Engine Operator - Pod Extra Init Containers
*/}}
{{- define "dremio.engine.operator.extraInitContainers" -}}
{{- $operatorExtraInitContainers := coalesce (($.Values.engine).operator).extraInitContainers $.Values.extraInitContainers -}}
{{- if $operatorExtraInitContainers -}}
{{ tpl $operatorExtraInitContainers $ }}
{{- end -}}
{{- end -}}

{{/*
Engine Operator - Container Extra Environment Variables
*/}}
{{- define "dremio.engine.operator.extraEnvs" -}}
{{- $operatorEnvironmentVariables := default (default (dict) $.Values.extraEnvs) (($.Values.engine).operator).extraEnvs -}}
{{- range $index, $environmentVariable:= $operatorEnvironmentVariables -}}
{{- if hasPrefix "DREMIO" $environmentVariable.name -}}
{{ fail "Environment variables cannot begin with DREMIO"}}
{{- end -}}
{{- end -}}
{{- if $operatorEnvironmentVariables -}}
{{ toYaml $operatorEnvironmentVariables }}
{{- end -}}
{{- end -}}

{{/*
Engine Operator - Deployment Annotations
*/}}
{{- define "dremio.engine.operator.annotations" -}}
{{- $operatorAnnotations := coalesce (($.Values.engine).operator).annotations $.Values.annotations -}}
{{- if $operatorAnnotations -}}
annotations:
  {{- toYaml $operatorAnnotations | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Engine Operator - Deployment Labels
*/}}
{{- define "dremio.engine.operator.labels" -}}
{{- $operatorLabels := coalesce (($.Values.engine).operator).labels $.Values.labels -}}
{{- if $operatorLabels -}}
labels:
  {{- toYaml $operatorLabels | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Engine Operator - Pod Annotations
*/}}
{{- define "dremio.engine.operator.podAnnotations" -}}
{{- $coordinatorPodAnnotations := coalesce (($.Values.engine).operator).podAnnotations $.Values.podAnnotations -}}
{{- if $coordinatorPodAnnotations -}}
{{ toYaml $coordinatorPodAnnotations }}
{{- end -}}
{{- end -}}

{{/*
Engine Operator - Pod Labels
*/}}
{{- define "dremio.engine.operator.podLabels" -}}
{{- $operatorPodLabels := coalesce (($.Values.engine).operator).podLabels $.Values.podLabels -}}
{{- if $operatorPodLabels -}}
{{ toYaml $operatorPodLabels }}
{{- end -}}
{{- end -}}

{{/*
Engine Operator - Pod Node Selectors
*/}}
{{- define "dremio.engine.operator.nodeSelector" -}}
{{- $operatorNodeSelector := coalesce (($.Values.engine).operator).nodeSelector $.Values.nodeSelector -}}
{{- if $operatorNodeSelector -}}
nodeSelector:
  {{- toYaml $operatorNodeSelector | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Engine Operator - Pod Tolerations
*/}}
{{- define "dremio.engine.operator.tolerations" -}}
{{- $operatorTolerations := coalesce (($.Values.engine).operator).tolerations $.Values.tolerations -}}
{{- if $operatorTolerations -}}
tolerations:
  {{- toYaml $operatorTolerations | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Engine Operator - Pod Security Context
*/}}
{{- define "dremio.engine.operator.podSecurityContext" -}}
securityContext:
  fsGroup: 999
  fsGroupChangePolicy: OnRootMismatch
{{- end -}}

{{/*
Engine Operator - Container Security Context
*/}}
{{- define "dremio.engine.operator.containerSecurityContext" -}}
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  privileged: false
  readOnlyRootFilesystem: false
  runAsGroup: 999
  runAsNonRoot: true
  runAsUser: 999
  seccompProfile:
    type: RuntimeDefault
{{- end -}}
