{{- define "testhub.cacerts.container" }}
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
    shopt -s nullglob
    for f in /usr/share/pki/usercerts/*.crt
    do
      _alias="${f##*/}"
      _alias="${_alias%.crt}"

      if [ -s "$f" ]; then
        import "$_alias" "$f"
      else
        keytool -delete -noprompt -alias "$_alias" -keystore /var/pki/java/combined/cacerts -storepass changeit
      fi
    done
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
  volumeMounts:
  - name: trust-store
    mountPath: /var/pki/java/combined
{{- if .ingressSecret }}
  - name: ingress
    mountPath: /usr/share/pki/ingress
    readOnly: true
{{- end }}
  - name: usercerts
    mountPath: /usr/share/pki/usercerts
    readOnly: true
{{- range .extras }}
  - name: {{ . }}
    mountPath: /usr/share/pki/{{ . }}
    readOnly: true
{{- end }}
{{- end }}

{{- define "testhub.cacerts.volumeMount" }}
- name: trust-store
  mountPath: {{ .path }}
  readOnly: true
  subPath: cacerts
{{- end }}

{{- define "testhub.cacerts.volumes" }}
- name: trust-store
  emptyDir: {}
{{- if .ingressSecret }}
- name: ingress
  secret:
    secretName: '{{ .ingressSecret }}'
{{- end }}
- name: usercerts
  secret:
    optional: true
    secretName: '{{ .usercertsSecret | default "usercerts" }}'
{{- end }}
