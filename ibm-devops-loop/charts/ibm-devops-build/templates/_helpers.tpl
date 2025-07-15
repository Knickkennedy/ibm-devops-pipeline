{{- define "ibm-devops-build.labels" -}}
app.kubernetes.io/instance: '{{ .Release.Name }}'
app.kubernetes.io/managed-by: '{{ .Release.Service }}'
app.kubernetes.io/name: devops-build
app.kubernetes.io/part-of: '{{ .Chart.Name }}'
app.kubernetes.io/version: '{{ regexReplaceAll "-.*" .Chart.AppVersion "" }}'
helm.sh/chart: '{{ .Chart.Name }}-{{ .Chart.Version }}'
{{- end }}

{{- define "devopsbuild.securityContext" -}}
securityContext:
  runAsNonRoot: true
{{- if not (.Capabilities.APIVersions.Has "security.openshift.io/v1") }}
  runAsUser: 1001
  fsGroup: 1001
{{- else }}
  supplementalGroups: [1001]
{{- end }}
  seccompProfile:
    type: RuntimeDefault
{{- end -}}

{{- define "devopsbuild.containerSecurityContext" -}}
securityContext:
  privileged: false
  readOnlyRootFilesystem: false
  allowPrivilegeEscalation: false
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault
  capabilities:
    drop:
      - ALL
{{- if not (.Capabilities.APIVersions.Has "security.openshift.io/v1") }}
  runAsUser: 1001   # UID for 'ucb'
{{- end }}
{{- end -}}