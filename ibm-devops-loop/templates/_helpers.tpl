{{/*
Check required global values
*/}}
{{- define "devops-platform.checkRequiredValues" -}}
{{- if not .Values.license -}}
    {{- fail "The license agreement must be accepted by setting .Values.license=true." -}}
{{- end -}}
{{- if not .Values.global.domain -}}
    {{- fail "A valid .Values.global.domain is required." -}}
{{- end -}}
{{- if not .Values.global.passwordSeed -}}
    {{- fail "A valid .Values.global.passwordSeed is required." -}}
{{- end -}}
 
 
{{- $selfSigned := false -}}
{{- if hasKey .Values "ibm-devops-prod" -}}
{{- $selfSigned = index .Values "ibm-devops-prod" "ingress" "cert" "selfSigned" -}}
{{- end -}}

{{- if hasKey .Values "hcl-devops" -}}
{{- $selfSigned = index .Values "hcl-devops" "ingress" "cert" "selfSigned" -}}
{{- end -}}

{{- if $selfSigned }}
  {{- $certSecretName := .Values.global.ibmCertSecretName | default .Values.global.hclCertSecretName }}
  {{- if not $certSecretName }}
    {{- fail "A valid .Values.global.ibmCertSecretName or .Values.global.hclCertSecretName is required if selfSigned is enabled." -}}
  {{- end }}
{{- end }}
{{- end -}}

{{/*

{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "devops-platform.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name with intentional redundancy.
*/}}
{{- define "devops-platform.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "devops-platform.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create component full name for use in metadata resource names that cannot exceed 63 characters
*/}}
{{- define "devops-platform.componentFullname" -}}
{{- $context := .context | default . -}}
{{- if not .componentName -}}
{{- fail "No componentName provided. componentName is required." -}}
{{- end -}}
{{- $componentName := .componentName -}}
{{- $fullName := include "devops-platform.fullname" $context -}}
{{- $componentFullName := printf "%s-%s" $fullName $componentName | trimSuffix "-" }}
{{- if gt (len $componentFullName) 63 -}}
{{- fail "Component name is too long.  The full name cannot be greater than 63 characters" -}}
{{- else -}}
{{- print $componentFullName -}}
{{- end -}}
{{- end }}


{{/*
Apply common labels
*/}}
{{- define "devops-platform.labels" -}}
{{- $context := .context -}}
{{- $componentName := .componentName -}}
{{- with $context -}}
helm.sh/chart: {{ include "devops-platform.chart" $context }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: {{ $componentName }}
{{ include "devops-platform.selectorLabels" (dict "componentName" $componentName "context" $context) }}
{{- end }}
{{- end }}


{{/*
Apply common selector labels
*/}}
{{- define "devops-platform.selectorLabels" -}}
{{- $componentName := .componentName -}}
{{- with .context -}}
app.kubernetes.io/name: {{ include "devops-platform.componentFullname" (dict "componentName" $componentName "context" .) }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "devops-platform.serviceAccountName" -}}
{{- $context := .context -}}
{{- $componentName := .componentName -}}
{{- with $context -}}
{{- if (index .Values $componentName "serviceAccount" "create") }}
{{- default (printf "%s-%s" (include "devops-platform.fullname" $context) $componentName) (index .Values $componentName "serviceAccount" "name") }}
{{- else }}
{{- default "default" (index .Values $componentName "serviceAccount" "name") }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Image to use for a component
*/}}
{{- define "devops-platform.image" -}}
{{- $context := .context -}}
{{- $componentName := .componentName -}}
{{- with $context -}}
{{- $imageRegistry := .Values.platform.imageRegistry | default .Values.global.imageRegistry -}}
{{- $image := index .Values $componentName "image" -}}
{{- if index .Values $componentName "localImage" | default false -}}
{{- printf "%s" (trimPrefix "/" $image) -}}
{{- else -}}
{{- printf "%s/%s" (trimSuffix "/" $imageRegistry) (trimPrefix "/" $image) -}}
{{- end }}
{{- end }}
{{- end }}


{{- define "devops-platform.container.keycloak-init-sh-env" }}
{{- if index .Values "ibm-devops-prod" "ingress" "cert" "selfSigned" }}
- name: CAFILE
  value: '--cacert /usr/share/pki/ingress/ca.crt'
{{- end }}
- name: INGRESS_DOMAIN
  value: '{{ .Values.global.domain }}'
- name: KEYCLOAK_URL
  value: https://$(INGRESS_DOMAIN){{ index .Values "ibm-devops-prod" "keycloak" "path" }}
- name: REALM_NAME
  value: {{ index .Values "ibm-devops-prod" "keycloak" "realm" }}
- name: ADMIN_NAME
  value: {{ index .Values "ibm-devops-prod" "keycloak" "username" }}
- name: ADMIN_PASS
  valueFrom:
    secretKeyRef:
      key: password
      name: '{{ .Release.Name }}-keycloak'
{{- end }}

{{- define "devops-platform.container.keycloak-init-sh-trailer" }}
image: {{ include "devops-platform.image" (dict "componentName" "init" "context" .) }}
workingDir: /usr/local/bin
imagePullPolicy: {{ .Values.init.imagePullPolicy | default .Values.platform.imagePullPolicy }}
{{- with .Values.platform.securityContext }}
securityContext:
{{ toYaml . | indent 2 }}
{{- end }}
volumeMounts:
{{- if index .Values "ibm-devops-prod" "ingress" "cert" "selfSigned" }}
- name: ingress
  mountPath: /usr/share/pki/ingress
{{- end }}
- name: keycloak-sh
  mountPath: /usr/local/bin
- name: tmp
  mountPath: /tmp
{{- end }}

{{- define "devops-platform.volumes.keycloak-init-sh" }}
        - name: keycloak-sh
          configMap:
            defaultMode: 365
            name: {{ include "devops-platform.componentFullname" (dict "componentName" "keycloak-init-sh" "context" .) }}
        - name: tmp
          emptyDir: {}
{{- end }}

{{- define "devops-platform.volumes.tmp-volume" }}
        - name: tmp-volume
          emptyDir: {}
{{- end }}

{{- define "devops-platform.path.trust-store" -}}
/opt/java/openjdk/lib/security/cacerts
{{- end }}

{{- define "devops-platform.initContainers.trust-store" }}
{{- $isSelfSigned := index .Values "ibm-devops-prod" "ingress" "cert" "selfSigned" }}
{{- $image := .image }}
{{- $myDict := dict "image" $image -}}
{{- $_ := set $myDict "path" (include "devops-platform.path.trust-store" .) -}}
{{- if eq .Chart.Name "hcl-devops-loop" }}
  {{- $_ := set $myDict "ingressSecret" (ternary .Values.global.hclCertSecretName "" $isSelfSigned) -}}
{{- else }}
  {{- $_ := set $myDict "ingressSecret" (ternary .Values.global.ibmCertSecretName "" $isSelfSigned) -}}
{{- end }}
{{- $_ := set $myDict "resources" .Values.init.resources -}}
{{- $_ := set $myDict "extras" .extras -}}
{{- include "devops-platform.cacerts.container" $myDict | indent 6 }}
{{- end }}

{{- define "devops-platform.volumes.trust-store" }}
{{- $isSelfSigned := index .Values "ibm-devops-prod" "ingress" "cert" "selfSigned" }}
{{- $myDict := dict -}}
{{- if eq .Chart.Name "hcl-devops-loop" }}
  {{- $_ := set $myDict "ingressSecret" (ternary .Values.global.hclCertSecretName "" $isSelfSigned) -}}
{{- else }}
  {{- $_ := set $myDict "ingressSecret" (ternary .Values.global.ibmCertSecretName "" $isSelfSigned) -}}
{{- end }}
{{- include "devops-platform.cacerts.volumes" $myDict | indent 6 }}
{{- end }}


{{- define "devops-platform.volumeMounts.trust-store" }}
{{- include "devops-platform.cacerts.volumeMount" (dict "path" (include "devops-platform.path.trust-store" .)) | indent 12 }}
{{- end }}


{{- define "devops-platform.cacerts.container" }}
- command:
  - /bin/bash
  - -ec
  - |
    import() {
      keytool -import -noprompt -alias "$1" -keystore /var/pki/java/combined/cacerts -storepass changeit -file "$2"
    }

    cp -L -f "{{ .path }}" /var/pki/java/combined/cacerts
    ls -l /var/pki/java/combined/cacerts
    chmod +w /var/pki/java/combined/cacerts; echo "chmod"
    ls -l /var/pki/java/combined/cacerts

    if [ -s /usr/share/pki/ingress/ca.crt ]; then
      import ingress /usr/share/pki/ingress/ca.crt
    fi
{{- range .extras }}
    if [ -s /usr/share/pki/{{ . }}/ca.crt ]; then
      import {{ . }} /usr/share/pki/{{ . }}/ca.crt
    fi
{{- end }}
    keytool -list -keystore "{{ .path }}" -storepass changeit | grep entries
    keytool -list -keystore /var/pki/java/combined/cacerts -storepass changeit
  image: '{{ .image }}'
  imagePullPolicy: IfNotPresent
  name: trust-store
{{- if .resources }}
  resources: {{- toYaml .resources | nindent 4 }}
{{- end }}
  securityContext:
    privileged: false
    readOnlyRootFilesystem: true
    allowPrivilegeEscalation: false
    capabilities:
      drop:
      - ALL
    seccompProfile:
      type: RuntimeDefault
  volumeMounts:
  - name: trust-store
    mountPath: /var/pki/java/combined
  - name: tmp-volume
    mountPath: /tmp
{{- if .ingressSecret }}
  - name: ingress
    mountPath: /usr/share/pki/ingress
    readOnly: true
{{- end }}
{{- range .extras }}
  - name: {{ . }}
    mountPath: /usr/share/pki/{{ . }}
    readOnly: true
{{- end }}
{{- end }}


{{- define "devops-platform.cacerts.volumes" }}
  - name: trust-store
    emptyDir: {}
{{- if .ingressSecret }}
  - name: ingress
    secret:
      secretName: '{{ .ingressSecret }}'
{{- end }}
{{- end }}

{{- define "devops-platform.cacerts.volumeMount" }}
- name: trust-store
  mountPath: {{ .path }}
  readOnly: true
  subPath: cacerts
- name: tmp-volume
  mountPath: /tmp
{{- end }}

{{/*
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

{{- define "devops-platform.initContainers.pg-isready" }}
      - command:
        - sh
        - -c
        - |
          until pg_isready -U {{ .dbName }} -h {{ .Release.Name }}-postgresql \
            && echo "SELECT FROM pg_database WHERE datname = '{{ .dbName }}'" |
               psql -h {{ .Release.Name }}-postgresql -U {{ .dbName }} |
               grep '1 row'
          do
            sleep 15
          done
        env:
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              key: postgresql-password
              name: '{{ .secret | default (include "devops-platform.componentFullname" (dict "componentName" .dbName "context" .)) }}'
        image: '{{ (default (index .Values "ibm-devops-prod" "imageRegistry") (index .Values "ibm-devops-prod" "postgresql" "registry")) }}/{{ regexReplaceAll (index .Values "ibm-devops-prod" "imageRepoRegex") (index .Values "ibm-devops-prod" "postgresql" "image") (index .Values "ibm-devops-prod" "imageRepoRepl") }}'
        imagePullPolicy: IfNotPresent
        name: pg-isready
{{- if index .Values "ibm-devops-prod" "init" "resources" }}
        resources: {{- toYaml (index .Values "ibm-devops-prod" "init" "resources") | nindent 10 }}
{{- end }}
        securityContext: 
{{- if index .Values "ibm-devops-prod" "containerSecurityContext" }}
{{ toYaml (index .Values "ibm-devops-prod" "containerSecurityContext") | nindent 10 }}
{{- end }}
{{- end }}

{{- define "devops-platform.initContainers.liquibase-update" }}
      - command:
        - /liquibase/liquibase-update.sh
        env:
        - name: URL
          value: "jdbc:postgresql://{{ .Release.Name }}-postgresql:5432/{{ .dbName }}"
        - name: USERNAME
          value: "{{ .dbName }}"
        - name: PASSWORD
          valueFrom:
            secretKeyRef:
              key: postgresql-password
              name: '{{ .secret | default (include "devops-platform.componentFullname" (dict "componentName" .svc "context" .)) }}'
        image: {{ .image }}
        imagePullPolicy: IfNotPresent
        name: liquibase-update
{{- if index .Values "ibm-devops-prod" "init" "liquibase" "resources" }}
        resources: {{- toYaml (index .Values "ibm-devops-prod" "init" "liquibase" "resources") | nindent 10 }}
{{- end }}
        securityContext: 
{{- if index .Values "ibm-devops-prod" "containerSecurityContext" }}
{{ toYaml (index .Values "ibm-devops-prod" "containerSecurityContext") | nindent 10 }}
{{- end }}
{{- end }}

{{- define "devops-platform.initContainers.keycloak-add-realm-roles-groups" }}
- name: add-realm-roles-groups
  command:
  - sh
  - -ec
  - |
    ./wait.sh $KEYCLOAK_URL/realms/$REALM_NAME/
    ./add-realm-roles-groups.sh
  env:
{{ include "devops-platform.container.keycloak-init-sh-env" . | nindent 4 }}
    - name: REALM_ROLES
      value: {{ index .Values "keycloak" "realmRoles" | quote }}
    - name: REALM_GROUPS
      value: {{ index .Values "keycloak" "realmGroups" | quote }}
{{ include "devops-platform.container.keycloak-init-sh-trailer" . | nindent 2 }}
{{- end }}

{{/*
Return the brand of the install
*/}}
{{- define "devops-platform.brand" -}}
{{- if eq .Chart.Name "ibm-devops-loop" -}}
IBM
{{- else -}}
HCL
{{- end -}}
{{- end }}

{{/*
Define environment variables wiring in product info such as base URLs
*/}}
{{- define "devops-platform.container.product-env" }}
            - name: AUTOMATION_TENANT_URL
              value: 'https://{{ .Values.global.domain }}{{ index .Values "tenant" "ingress" "path" }}'
            - name: AUTOMATION_LOOP_URL
              value: 'https://{{ .Values.global.domain }}{{ index .Values "loop" "ingress" "path" }}'
            - name: AUTOMATION_ANALYTICSAI_URL
              value: 'https://{{ .Values.global.domain }}{{ index .Values "analyticsai" "ingress" "path" }}'
            - name: AUTOMATION_LICENSING_URL
              value: 'https://{{ .Values.global.domain }}{{ index .Values "licensing" "ingress" "path" }}'
            - name: AUTOMATION_PRODUCT_TEST_ENABLED
              value: 'true'
            - name: AUTOMATION_PRODUCT_TEST_URL
              value: 'https://{{ .Values.global.domain }}{{ index .Values "ibm-devops-prod" "ingress" "path" }}'
            - name: AUTOMATION_PRODUCT_PLAN_ENABLED
              value: '{{ .Values.platform.plan.enabled }}'
            - name: AUTOMATION_PRODUCT_PLAN_URL
              value: 'https://{{ .Values.global.domain }}{{ index .Values "ibm-devopsplan-prod" "ingress" "path" }}'
            - name: AUTOMATION_PRODUCT_CONTROL_ENABLED
              value: '{{ .Values.platform.plan.enabled }}'
            - name: AUTOMATION_PRODUCT_CONTROL_URL
              value: 'https://{{ .Values.global.domain }}{{ index .Values "ibm-devopsplan-prod" "control" "ingress" "path" }}'
            - name: AUTOMATION_PRODUCT_VELOCITY_ENABLED
              value: '{{ .Values.platform.velocity.enabled }}'
            - name: AUTOMATION_PRODUCT_VELOCITY_URL
              value: 'https://{{ .Values.global.domain }}{{ index .Values "ibm-ucv-prod" "ingress" "path" }}'
            - name: AUTOMATION_PRODUCT_MEASURE_URL
              value: 'https://{{ .Values.global.domain }}{{ index .Values "ibm-ucv-prod" "ingress" "path" }}/valuestreams'
            - name: AUTOMATION_PRODUCT_RELEASE_URL
              value: 'https://{{ .Values.global.domain }}{{ index .Values "ibm-ucv-prod" "ingress" "path" }}/releases'
            - name: AUTOMATION_PRODUCT_DEPLOY_ENABLED
              value: '{{ .Values.platform.deploy.enabled }}'
            - name: AUTOMATION_PRODUCT_DEPLOY_URL
              value: 'https://{{ .Values.global.domain }}{{ index .Values "ibm-ucd-prod" "ingress" "path" }}'
            - name: AUTOMATION_PRODUCT_CODE_ENABLED
              value: '{{ .Values.platform.code.enabled }}'
            - name: AUTOMATION_PRODUCT_CODE_URL
              value: 'https://{{ .Values.global.domain }}{{ index .Values "ibm-devopscode" "ingress" "path" }}'
            - name: AUTOMATION_PRODUCT_BUILD_ENABLED
              value: '{{ .Values.platform.build.enabled }}'
{{- end }}
