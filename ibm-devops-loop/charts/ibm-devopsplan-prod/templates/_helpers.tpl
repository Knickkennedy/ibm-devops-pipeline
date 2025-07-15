{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "ccm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

Set devopsplan name.
*/}}
{{- define "plan.fullname" -}}
devopsplan
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ccm.fullname" -}}
{{- if .Values.global.fullnameOverride }}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "ccm.subchart.fullname" -}}
{{- if .Values.global.fullnameOverride }}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Values.parent.chartName .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ccm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ccm.labels" -}}
helm.sh/chart: {{ include "ccm.chart" . }}
{{ include "ccm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ccm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ccm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ccm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ccm.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image repository
*/}}
{{- define "ccm.ccmImageRepo" -}}
{{- if eq .Values.global.imageRegistry "hclcr.io/sofy" -}}
hclcr.io
{{- else if eq .Values.global.imageRegistry "gcr.io/blackjack-209019" -}}
gcr.io/blackjack-209019/services
{{- else -}}
{{ print .Values.global.imageRegistry }}
{{- end -}}
{{- end -}}

{{- define "ccm.app-version" -}}
{{- if eq .Values.global.devopsPlanBrand "HCL" -}}
3.0.4
{{- else if eq .Values.global.devopsPlanBrand "IBM" -}}
3.0.4
{{- end -}}
{{- end -}}

{{- define "ccm.app-folder" -}}
{{- if eq .Values.global.devopsPlanBrand "HCL" -}}
/opt/devops/plan/devopsplan-rest-server-distribution
{{- else if eq .Values.global.devopsPlanBrand "IBM" -}}
/opt/devops/plan/devopsplan-rest-server-distribution
{{- else -}}
/opt/devops/plan/devopsplan-rest-server-distribution
{{- end -}}
{{- end -}}

{{- define "analytics.app-folder" -}}
{{- if eq .Values.global.devopsPlanBrand "HCL" -}}
/opt/devops/plan/analytics-rest-server-distribution
{{- else if eq .Values.global.devopsPlanBrand "IBM" -}}
/opt/devops/plan/analytics-rest-server-distribution
{{- else -}}
/opt/devops/plan/analytics-rest-server-distribution
{{- end -}}
{{- end -}}

{{- define "mychart.caCertExists" -}}
{{- $caCertExists := "false" }}

{{- if and (.Values.global.platform.enabled) (.Values.global.ibmCertSecretName) }}
  {{- $ibmSecret := lookup "v1" "Secret" .Release.Namespace .Values.global.ibmCertSecretName }}
  {{- if and $ibmSecret (index $ibmSecret.data "ca.crt") }}
    {{- $caCertExists = "true" }}
  {{- end }}
{{- else if and (.Values.global.platform.enabled) (.Values.global.hclCertSecretName) }}
  {{- $hclSecret := lookup "v1" "Secret" .Release.Namespace .Values.global.hclCertSecretName }}
  {{- if and $hclSecret (index $hclSecret.data "ca.crt") }}
    {{- $caCertExists = "true" }}
  {{- end }}
{{- end }}

{{- $caCertExists -}}
{{- end }}

Generate a password for postgresql
*/}}
{{- define "devops-platform.postgresql-password" -}}
{{- $context := .context -}}
{{- $pwseed := .passwordSeed -}}
{{- $cname := .componentName -}}
{{- $epwd := .existingPwd -}}
{{- with $context -}}
{{- if $epwd }}
{{- print $epwd }}
{{- else }}
{{- printf "%s%s-%s" (default .Release.Name $pwseed) $cname "postgresql" | sha256sum }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Generate a base64 password for postgresql
*/}}
{{- define "devops-platform.postgresql-password-b64" -}}
{{ printf "  %s: %s" "postgresql-password" ( include "devops-platform.postgresql-password" . | b64enc | quote )}}
{{- end }}

{{- define "ccm.url" -}}
{{- if .Values.global.domain }}
{{- if .Values.global.platform.enabled }}
https://{{ .Values.global.domain }}{{ .Values.ingress.path }}
{{- else }}
https://{{ include "ccm.fullname" . }}{{ .Values.ingress.suffix }}.{{ .Values.global.domain }}
{{- end }}
{{- else if .Values.global.sofySolutionContext }}
https://{{ include "ccm.fullname" . }}{{ .Values.ingress.suffix }}.{{- include "sofy-domain.configMapKeyRef"}}
{{- else if ( .Values.service.urlMapping ) }}
{{ .Values.service.urlMapping }}
{- else if and (or (eq "NodePort" .Values.service.type ) (eq "LoadBalancer" .Values.service.type )) (.Values.service.exposePort )) }}
{{- if .Values.service.ipAddress }}
"https://{{ .Values.service.ipAddress }}:{{ .Values.service.exposePort }}"
{{- else }}
"https://{{ .Values.keycloak.service.ipAddress }}:{{ .Values.service.exposePort }}"
{{- end }}
{{- else if .Values.service.urlMapping }}
"{{ .Values.service.urlMapping }}"
{{- end }}
{{- end }}

{{- define "dashboard.url" -}}
{{- if .Values.global.domain }}
{{- if .Values.nginx.service }}
https://{{ include "ccm.fullname" . }}-nginx{{ .Values.ingress.suffix }}.{{ .Values.global.domain }}
{{- end }}
{{- else if .Values.global.sofySolutionContext }}
{{- if .Values.nginx.service }}
https://{{ include "ccm.fullname" . }}-nginx{{ .Values.ingress.suffix }}.{{- include "sofy-domain.configMapKeyRef"}}
{{- end }}
{{- else if ( .Values.nginx.urlMapping ) }}
{{ .Values.nginx.urlMapping }}
{- else if and (or (eq "NodePort" .Values.nginx.type ) (eq "LoadBalancer" .Values.nginx.type )) (.Values.nginx.exposePort )) }}
{{- if .Values.service.ipAddress }}
"https://{{ .Values.service.ipAddress }}:{{ .Values.nginx.exposePort }}"
{{- else }}
"https://{{ .Values.keycloak.service.ipAddress }}:{{ .Values.nginx.exposePort }}"
{{- end }}
{{- else if .Values.nginx.urlMapping }}
"{{ .Values.nginx.urlMapping }}"
{{- end }}
{{- end }}

{{- define "keycloaksrv.common.names.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}
