{{/* vim: set filetype=mustache: */}}

{{- define "root.url.appHome" -}}
  {{- $vars := merge (dict) . -}}
  {{- $_ := set $vars "ucvServicePath" "" -}}
  {{- template "ucv.appPath" $vars }}
{{- end -}}

{{- define "root.url.cr" -}}
  {{- $vars := merge (dict) . -}}
  {{- $_ := set $vars "ucvServicePath" "deploymentPlans" -}}
  {{- template "ucv.appPath" $vars }}
{{- end -}}

{{- define "root.url.securityAuth" -}}
  {{- $vars := merge (dict) . -}}
  {{- $_ := set $vars "ucvServicePath" "security-api/auth" -}}
  {{- template "ucv.appPath" $vars }}
{{- end -}}

{{- define "root.url.securityApiHost" -}}
  {{- $vars := merge (dict) . -}}
  {{- $_ := set $vars "ucvServicePath" "security-api" -}}
  {{- template "ucv.appPath" $vars }}
{{- end -}}

{{- define "root.url.mapApi" -}}
  {{- $vars := merge (dict) . -}}
  {{- $_ := set $vars "ucvServicePath" "multi-app-pipeline-api" -}}
  {{- template "ucv.appPath" $vars }}
{{- end -}}

{{- define "root.url.releaseEventsApi" -}}
  {{- $vars := merge (dict) . -}}
  {{- $_ := set $vars "ucvServicePath" "release-events-api" -}}
  {{- template "ucv.appPath" $vars }}
{{- end -}}

{{- define "root.url.reportingConsumer" -}}
  {{- $vars := merge (dict) . -}}
  {{- $_ := set $vars "ucvServicePath" "reporting-consumer" -}}
  {{- template "ucv.appPath" $vars }}
{{- end -}}

{{- define "ucv.appPath" -}}
{{- $ingressPath := .Values.ingress.path | trimSuffix "/" -}}
{{- $domain := include "ucv.domain" . -}}
{{- printf "%s://%s:%s%s/%s" .Values.url.protocol $domain (.Values.url.port | toString) $ingressPath .ucvServicePath -}}
{{- end -}}

{{- define "ucv.domain" -}}
{{- if ((.Values.global).domain) -}}
{{ tpl .Values.global.domain . }}
{{- else -}}
{{ tpl .Values.url.domain . }}
{{- end -}}
{{- end -}}

{{- define "ucv.nodeAffinity" -}}
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
    - matchExpressions:
      - key: kubernetes.io/arch
        operator: In
        values:
        - amd64
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 1
    preference:
      matchExpressions:
      - key: kubernetes.io/arch
        operator: In
        values:
        - amd64
  - weight: 1
    preference:
      matchExpressions:
      - key: ucv/workload-class
        operator: In
        values:
        - {{ .ucvWorkloadClass }}
{{- end -}}

{{- define "ucv.resources" -}}
limits:
  memory: {{ (index .Values.resources.limits.memory .ucvService) | default .Values.resources.limits.memory.default }}
  cpu: {{ (index .Values.resources.limits.cpu .ucvService) | default .Values.resources.limits.cpu.default }}
  ephemeral-storage: {{ (index .Values.resources.limits.storage .ucvService) | default .Values.resources.limits.storage.default }}
requests:
  memory: {{ (index .Values.resources.requests.memory .ucvService) | default .Values.resources.requests.memory.default }}
  cpu: {{ (index .Values.resources.requests.cpu .ucvService) | default .Values.resources.requests.cpu.default }}
  ephemeral-storage: {{ (index .Values.resources.requests.storage .ucvService) | default .Values.resources.requests.storage.default }}
{{- end -}}

{{- define "ucv.maxOldSpaceSize" -}}
{{- $memoryValue := (index .Values.resources.limits.memory .ucvService | default .Values.resources.limits.memory.default) -}}
{{- if hasSuffix "Gi" $memoryValue}}
  {{- $memoryValue = (trimSuffix "Gi" $memoryValue | atoi | mul 1073)}}
{{- else if hasSuffix "Mi" $memoryValue}}
  {{- $memoryValue = (trimSuffix "Mi" $memoryValue | atoi | mul 1)}}
{{- else if hasSuffix "Ki" $memoryValue}}
  {{- $memoryValue = (trimSuffix "Ki" $memoryValue | atoi | mul 0.001024 | int)}}
{{- else if hasSuffix "G" $memoryValue}}
  {{- $memoryValue = (trimSuffix "G" $memoryValue | atoi | mul 1000)}}
{{- else if hasSuffix "M" $memoryValue}}
  {{- $memoryValue = (trimSuffix "M" $memoryValue | atoi | mul 1)}}
{{- else if hasSuffix "k" $memoryValue}}
  {{- $memoryValue = (trimSuffix "k" $memoryValue | atoi | mul 0.001 | int)}}
{{- end }}
value: '--max-old-space-size={{ $memoryValue }}'
{{- end -}}

{{- define "ucv.productAnnotations" -}}
productName: 'IBM DevOps Velocity'
productID: "953596c2753a426991bd2c076aa5a51c"
productMetric: "FLOATING_USER"
productChargedContainers: "All"
productVersion: '{{ .Chart.Version }}'
{{- end -}}

{{- define "ucv.securityContext" -}}
privileged: false
readOnlyRootFilesystem: false
allowPrivilegeEscalation: false
runAsNonRoot: true
runAsUser: {{ ternary "" .Values.runAsUser (eq "null" (toString .Values.runAsUser)) }}
capabilities:
  drop:
  - ALL
seccompProfile:
  type: RuntimeDefault
{{- end -}}

{{- define "ucv.imagePullSecrets" -}}
{{- if eq (((.Values.global).platform).enabled) (true) }}
{{- with .Values.global.imagePullSecrets }}
  {{- toYaml . }}
{{- end }}
{{- end }}
{{- if .Values.secrets.imagePull }}
- name: {{.Values.secrets.imagePull}}
{{- end }}
- name: "sa-{{ .Release.Namespace }}"
{{- end -}}

{{- define "ucv.labels" -}}
app: velocity
app.kubernetes.io/name: velocity
chart: '{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}'
helm.sh/chart: '{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}'
release: '{{ .Release.Name }}'
app.kubernetes.io/instance: {{ .Release.Name }}
heritage: '{{ .Release.Service }}'
app.kubernetes.io/managed-by: '{{ .Release.Service }}'
{{- end -}}

{{- define "ucv.specTemplateLabels" -}}
app: velocity
app.kubernetes.io/name: velocity
chart: '{{ .Chart.Name }}'
helm.sh/chart: '{{ .Chart.Name }}'
release: '{{ .Release.Name }}'
app.kubernetes.io/instance: {{ .Release.Name }}
heritage: '{{ .Release.Service }}'
app.kubernetes.io/managed-by: '{{ .Release.Service }}'
service: {{ .ucvService }}
{{- end -}}

{{- define "ucv.selector" -}}
app: velocity
release: {{ .Release.Name }}
service: {{ .ucvService }}
{{- end -}}

{{- define "ucv.livenessProbe" -}}
httpGet:
  path: {{ .ucvLivenessPath | default "/alive" }}
  port: {{ .ucvLivenessPort }}
{{ include "ucv.livenessProbeTimeouts" . }}
{{- end -}}

{{- define "ucv.livenessProbeTimeouts" -}}
initialDelaySeconds: {{ (index .Values.timeouts.liveness.initialDelaySeconds .ucvService) | default .Values.timeouts.liveness.initialDelaySeconds.default }}
timeoutSeconds: {{ (index .Values.timeouts.liveness.timeoutSeconds .ucvService) | default .Values.timeouts.liveness.timeoutSeconds.default }}
periodSeconds: {{ (index .Values.timeouts.liveness.periodSeconds .ucvService) | default .Values.timeouts.liveness.periodSeconds.default }}
failureThreshold: {{ (index .Values.timeouts.liveness.failureThreshold .ucvService) | default .Values.timeouts.liveness.failureThreshold.default }}
{{- end -}}

{{- define "ucv.readinessProbe" -}}
httpGet:
  path: {{ .ucvReadinessPath | default "/ready" }}
  port: {{ .ucvReadinessPort }}
{{ include "ucv.readinessProbeTimeouts" . }}
{{- end -}}

{{- define "ucv.readinessProbeTimeouts" -}}
initialDelaySeconds: {{ (index .Values.timeouts.readiness.initialDelaySeconds .ucvService) | default .Values.timeouts.readiness.initialDelaySeconds.default }}
timeoutSeconds: {{ (index .Values.timeouts.readiness.timeoutSeconds .ucvService) | default .Values.timeouts.readiness.timeoutSeconds.default }}
periodSeconds: {{ (index .Values.timeouts.readiness.periodSeconds .ucvService) | default .Values.timeouts.readiness.periodSeconds.default }}
failureThreshold: {{ (index .Values.timeouts.readiness.failureThreshold .ucvService) | default .Values.timeouts.readiness.failureThreshold.default }}
{{- end -}}

{{- define "ucv.mongoUrl" -}}
{{- if ((.Values.mongo).url) }}
value: {{ .Values.mongo.url }}
{{- else }}
valueFrom:
  secretKeyRef:
    name: {{ .Values.secrets.database }}
    key: password
{{- end }}
{{- end -}}

{{- define "ucv.mongoVolumeMounts" -}}
{{- if .Values.secrets.mongoTls }}
volumeMounts:
  {{ include "ucv.mongoTlsVolumeMount" . }}
{{- end }}
{{- end -}}

{{- define "ucv.mongoTlsVolumeMount" -}}
{{- if .Values.secrets.mongoTls }}
- name: mongo-ca-volume
  mountPath: /etc/ssl/certs
{{- end }}
{{- end -}}

{{- define "ucv.mongoVolumes" -}}
{{- if .Values.secrets.mongoTls }}
volumes:
  {{ include "ucv.mongoTlsVolume" . }}
{{- end }}
{{- end -}}

{{- define "ucv.mongoTlsVolume" -}}
{{- if .Values.secrets.mongoTls }}
- name: mongo-ca-volume
  secret:
    secretName: '{{ .Values.secrets.mongoTls }}'
    items:
      - key: mongo.pem
        path: mongo.pem
{{- end }}
{{- end -}}

{{- define "ucv.rabbit.nodePort" -}}
{{- if .Values.rabbitmq.nodePort }}
nodePort: {{ .Values.rabbitmq.nodePort }}
{{- end }}
{{- end -}}

{{- define "ucv.oidc.client.secret.name" -}}
{{- if ((.Values.platform).oidc).clientSecret -}}
{{ tpl ((.Values.platform).oidc).clientSecret . }}
{{- else -}}
{{ tpl .Values.secrets.tokens . }}
{{- end -}}
{{- end -}}

{{- define "ucv.image" -}}
{{ coalesce ((.Values.global).imageRegistry) .ucvImageRegistry }}{{.ucvImageRegistryPath}}{{.ucvImageName}}:{{.ucvImageTag}}
{{- end -}}

{{- define "ucv.external.image" -}}
{{ coalesce ((.Values.global).externalImageRegistry) .ucvImageRegistry }}{{.ucvImageName}}:{{.ucvImageTag}}
{{- end -}}