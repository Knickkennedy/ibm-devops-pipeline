{{- define "testhub.path.trust-store" -}}
/opt/java/openjdk/lib/security/cacerts
{{- end }}

{{- define "testhub.pod.security-context" }}
    {{- with .Values.securityContext }}
      securityContext: 
        {{- include "testhub.toYaml" . | indent 8 }}
    {{- end }}
{{- end }}

{{- define "testhub.container.security-context" }}
        securityContext: 
        {{- toYaml . | nindent 10 }}
{{- end }}

{{- define "testhub.volumeMounts.kube-api-access" }}
        - name: kube-api-access
          mountPath: /var/run/secrets/kubernetes.io/serviceaccount
{{- end }}

{{- define "testhub.volumes.kube-api-access" }}
      - name: kube-api-access
        projected:
          sources:
            - serviceAccountToken:
                path: token
            - configMap:
                items:
                  - key: ca.crt
                    path: ca.crt
                name: kube-root-ca.crt
            - downwardAPI:
                items:
                  - fieldRef:
                      apiVersion: v1
                      fieldPath: metadata.namespace
                    path: namespace
{{- end }}

{{- define "testhub.initContainers.trust-store" }}
{{- $myDict := dict "image" (printf "%s/%s" (default (default .Values.imageRegistry .Values.global.imageRegistry) .Values.init.registry) (regexReplaceAll .Values.imageRepoRegex .Values.init.image .Values.imageRepoRepl)) -}}
{{- $_ := set $myDict "path" (include "testhub.path.trust-store" .) -}}
{{- $_ := set $myDict "ingressSecret" (ternary .Values.global.ibmCertSecretName "" .Values.ingress.cert.selfSigned) -}}
{{- $_ := set $myDict "resources" .Values.init.resources -}}
{{- $_ := set $myDict "extras" .extras -}}
{{- include "testhub.cacerts.container" $myDict | indent 6 }}
{{- end }}

{{- define "testhub.volumes.trust-store" }}
{{- $myDict := dict "ingressSecret" (ternary .Values.global.ibmCertSecretName "" .Values.ingress.cert.selfSigned) -}}
{{- $_ := set $myDict "usercertsSecret" .Values.userCertsSecretName -}}
{{- include "testhub.cacerts.volumes" $myDict | indent 6 }}
{{- end }}

{{- define "testhub.container.keycloak-init-sh-env" }}
{{- if .Values.ingress.cert.selfSigned }}
        - name: CAFILE
          value: '--cacert /usr/share/pki/ingress/ca.crt'
{{- end }}
        - name: INGRESS_DOMAIN
          value: '{{ .Values.global.domain }}'
        - name: KEYCLOAK_URL
          value: https://$(INGRESS_DOMAIN){{ .Values.keycloak.path }}
        - name: REALM_NAME
          value: {{ .Values.keycloak.realm }}
        - name: ADMIN_NAME
          value: {{ .Values.keycloak.username }}
        - name: ADMIN_PASS
          valueFrom:
            secretKeyRef:
              key: password
              name: '{{ .Release.Name }}-keycloak'
{{- end }}

{{- define "testhub.container.keycloak-init-sh-trailer" }}
        image: '{{ (default (default .Values.imageRegistry .Values.global.imageRegistry) .Values.init.registry) }}/{{ regexReplaceAll .Values.imageRepoRegex .Values.init.image .Values.imageRepoRepl }}'
        workingDir: /usr/local/bin
        imagePullPolicy: IfNotPresent
{{- if (.Values.keycloak.job).resources }}
        resources: {{- toYaml .Values.keycloak.job.resources | nindent 10 }}
{{- end }}
{{- include "testhub.container.security-context" .Values.containerSecurityContext  }}
        volumeMounts:
{{- if .Values.ingress.cert.selfSigned }}
        - name: ingress
          mountPath: /usr/share/pki/ingress
{{- end }}
        - name: keycloak-sh
          mountPath: /usr/local/bin
        - name: tmp
          mountPath: /tmp
{{- end }}

{{- define "testhub.volumes.keycloak-init-sh" }}
      - name: keycloak-sh
        configMap:
          defaultMode: 365
          name: '{{ .Release.Name }}-keycloak-init-sh'
      - name: tmp
        emptyDir: {}
{{- end }}

{{- define "testhub.volumeMounts.trust-store" }}
{{- include "testhub.cacerts.volumeMount" (dict "path" (include "testhub.path.trust-store" .)) | indent 8 }}
{{- end }}

{{- define "testhub.initContainers.gateway-isready" }}
      - command:
        - sh
        - -c
        - |-
          until [[ '{"status":"UP"' == $(curl --connect-timeout 10 $GATEWAY_ENDPOINT{{ .Values.ingress.path }}/management/health | tr -d "[:space:]" | head -c 14) ]]
            do sleep 15
          done
        env:
        - name: GATEWAY_ENDPOINT
          value: http://gateway:8080
        image: '{{ (default (default .Values.imageRegistry .Values.global.imageRegistry) .Values.init.registry) }}/{{ regexReplaceAll .Values.imageRepoRegex .Values.init.image .Values.imageRepoRepl }}'
        imagePullPolicy: IfNotPresent
        name: gateway-isready
{{- if .Values.init.resources }}
        resources: {{- toYaml .Values.init.resources | nindent 10 }}
{{- end }}
{{- include "testhub.container.security-context" .Values.containerSecurityContext  }}
{{- end }}
{{- define "testhub.initContainers.core-isready" }}
      - command:
        - sh
        - -c
        - |-
          until [[ '{"status":"UP"' == $(curl --connect-timeout 10 $CORE_ENDPOINT{{ .Values.ingress.path }}/management/health | tr -d "[:space:]" | head -c 14) ]]
            do sleep 15
          done
        env:
        - name: CORE_ENDPOINT
          value: http://core:8080
        image: '{{ (default (default .Values.imageRegistry .Values.global.imageRegistry) .Values.init.registry) }}/{{ regexReplaceAll .Values.imageRepoRegex .Values.init.image .Values.imageRepoRepl }}'
        imagePullPolicy: IfNotPresent
        name: core-isready
{{- if .Values.init.resources }}
        resources: {{- toYaml .Values.init.resources | nindent 10 }}
{{- end }}
{{- include "testhub.container.security-context" .Values.containerSecurityContext  }}
{{- end }}
{{- define "testhub.initContainers.pg-isready" }}
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
              name: '{{ .secret | default (printf "%s-%s" .Release.Name .dbName) }}'
        image: '{{ (default (default .Values.imageRegistry .Values.global.imageRegistry) .Values.postgresql.registry) }}/{{ regexReplaceAll .Values.imageRepoRegex .Values.postgresql.image .Values.imageRepoRepl }}'
        imagePullPolicy: IfNotPresent
        name: pg-isready
{{- if .Values.init.resources }}
        resources: {{- toYaml .Values.init.resources | nindent 10 }}
{{- end }}
{{- include "testhub.container.security-context" .Values.containerSecurityContext  }}
{{- end }}
{{- define "testhub.initContainers.add-plugin" }}
      - command:
        - sh
        - -c
        - |
          mkdir -p /internal-ext/extensibility-libs || true
          cp -f /extensibility-libs/{{ .plugin }}-extensibility-{{ .host }}.jar /internal-ext/extensibility-libs/
        image: '{{ (default (default .Values.imageRegistry .Values.global.imageRegistry) (index (index .Values .pluginImage) "registry")) }}/{{ regexReplaceAll .Values.imageRepoRegex (index (index .Values .pluginImage) "image") .Values.imageRepoRepl }}'
        imagePullPolicy: IfNotPresent
        name: get-{{ .plugin }}
{{- if .Values.init.resources }}
        resources: {{- toYaml .Values.init.resources | nindent 10 }}
{{- end }}
{{- include "testhub.container.security-context" .Values.containerSecurityContext  }}
        volumeMounts:
        - mountPath: /internal-ext
          name: internal-ext
{{- end }}
{{- define "testhub.initContainers.liquibase-update" }}
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
              name: '{{ .Release.Name }}-{{ .svc }}'
        image: '{{ (default (default .Values.imageRegistry .Values.global.imageRegistry) (index (index .Values .svc) "registry")) }}/{{ regexReplaceAll .Values.imageRepoRegex (index (index .Values .svc) "image") .Values.imageRepoRepl }}'
        imagePullPolicy: IfNotPresent
        name: liquibase-update
{{- if .Values.init.liquibase.resources }}
        resources: {{- toYaml .Values.init.liquibase.resources | nindent 10 }}
{{- end }}
{{- include "testhub.container.security-context" .Values.containerSecurityContext  }}
{{- end }}

{{- define "testhub.demo.enabled" }}
  {{- if (.Values.demo).enabled }}
true
  {{- end }}
{{- end }}

{{- define "testhub.cdis.enabled" }}
  {{- if (and .Values.cdis.enabled (ne "keycloak" .Values.profile)) }}
true
  {{- end }}
{{- end }}

{{- define "testhub.core.enabled" }}
  {{- if (ne "keycloak" .Values.profile) }}
true
  {{- end }}
{{- end }}

{{- define "testhub.datasets.enabled" }}
  {{- if (ne "keycloak" .Values.profile) }}
true
  {{- end }}
{{- end }}

{{- define "testhub.execution.enabled" }}
  {{- if (ne "keycloak" .Values.profile) }}
true
  {{- end }}
{{- end }}

{{- define "testhub.extensions.enabled" }}
  {{- if (ne "keycloak" .Values.profile) }}
true
  {{- end }}
{{- end }}

{{- define "testhub.frontend.enabled" }}
  {{- if (ne "keycloak" .Values.profile) }}
true
  {{- end }}
{{- end }}

{{- define "testhub.rabbitmq.enabled" }}
  {{- if (ne "keycloak" .Values.profile) }}
true
  {{- end }}
{{- end }}

{{- define "testhub.results.enabled" }}
  {{- if (ne "keycloak" .Values.profile) }}
true
  {{- end }}
{{- end }}

{{- define "testhub.router.enabled" }}
  {{- if (ne "keycloak" .Values.profile) }}
true
  {{- end }}
{{- end }}

{{- define "testhub.rm.enabled" }}
  {{- if (and .Values.rm.enabled (ne "keycloak" .Values.profile)) }}
true
  {{- end }}
{{- end }}

{{- define "testhub.tam.enabled" }}
  {{- if (ne "keycloak" .Values.profile) }}
true
  {{- end }}
{{- end }}

{{- define "testhub.tests.enabled" }}
  {{- if (ne "keycloak" .Values.profile) }}
true
  {{- end }}
{{- end }}

{{- define "testhub.userlibs.enabled" }}
  {{- if (ne "keycloak" .Values.profile) }}
true
  {{- end }}
{{- end }}

{{- define "testhub.ibmImagePullSecret" }}
  {{- if .Values.global.ibmImagePullSecret }}
    {{- .Values.global.ibmImagePullSecret }}
  {{- else if (and .Values.global.ibmImagePullUsername .Values.global.ibmImagePullPassword) }}
    {{- .Release.Name }}-pull
  {{- else if (and .Values.global.imagePullSecrets (gt (len .Values.global.imagePullSecrets) 0)) }}
    {{- with index .Values.global.imagePullSecrets 0 }}
      {{- if eq (printf "%T" .) "string" }}
        {{- . }}
      {{- else }}
        {{- .name }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "testhub.rabbitmq.memoryHighWatermark" }}
  {{- if not (hasSuffix "Mi" .) }}
    {{- printf "RabbitMQ memory values must use Mi: %s" . | fail }}
  {{- end }}
  {{- . | trimSuffix "Mi" | mulf 0.70 | int64 }}MiB
{{- end }}

{{- define "testhub.toYaml" }}
  {{- if kindIs "map" . }}
    {{- if eq 0 (len .) }}
      {{- toYaml . }}
    {{- end }}
    {{- range $key, $value := . }}
      {{- if and (toString . | ne "null") (ne "invalid" (kindOf .)) }}
{{ $key }}: {{ include "testhub.toYaml" $value | indent 2 }}
      {{- end }}
    {{- end }}
  {{- else if kindIs "slice" . }}
    {{- if eq 0 (len .) }}
      {{- toYaml . }}
    {{- end }}
    {{- range $index, $element := . }}
- {{ include "testhub.toYaml" $element | indent 2 }}
    {{- end }}
  {{- else }}
    {{- toYaml . }}
  {{- end }}
{{- end }}
