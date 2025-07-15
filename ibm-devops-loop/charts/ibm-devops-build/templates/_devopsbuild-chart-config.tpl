{{/*
license  parameter must be set to true
*/}}
{{- define "{{ .Chart.Name }}.licenseValidate.build" -}}
  {{ $license := .Values.license.accept }}
  {{- if $license  -}}
    true
  {{- end -}}
{{- end -}}

{{/* Determine which image to use given the product version.  */}}
{{/* Values.version can be an imagespec to allow registries other than IBM ER */}}
{{- define "{{ .Chart.Name }}.imageSpec.build" -}}
{{- if .Values.image.repoDigests -}}
{{- if eq .Values.version "7.0.0.4" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:4f0cb59cbb7ce2b66da26902bdb106a6f7ff8a532caae8427d82a63494c0bd40
{{- end -}}
{{- if eq .Values.version "7.0.0.4-xframe" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:e9387e69a5ca157173ed94df5356174097f9fe25c14a0e9700d526b90cbd9f72
{{- end -}}
{{- if eq .Values.version "7.0.0.4-rebranded-blueribbon" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:90dc767cf33e14a1b2a4b9dd50797720abc3ff374d746bcd6a9387d2e11b8f31
{{- end -}}
{{- if eq .Values.version "7.0.0.4-iframe" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:36e104506b4b2b44612d3436b8599195f2a8bb74e57656baf2869d84b55c4362
{{- end -}}
{{- if eq .Values.version "7.1.0.int" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:2decd59823bed26d2be739bd80b2bfa762db3c689b8fe50334d901ed1abd65e7
{{- end -}}
{{- if eq .Values.version "7.1.0.int.2" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:b518aafe446bea9a16b3f4db7b402d39ddc8bbfecb2b65652324c82cf14cae17
{{- end -}}
{{- if eq .Values.version "7.1.0.int.3" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:6843fc5133148e26e6dfd58c724991c2c8a9fca24f2e20e0153a7ed08bbe7ebd
{{- end -}}
{{- if eq .Values.version "7.1.0.int-loginpage" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:20590291cd06810657682af8b5fc84d976deea40a80fdf7f8fdbc7bca43b1b90
{{- end -}}
{{- if eq .Values.version "7.1.0-1177092" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:f666058385929cc9692d30d46cac4b459ca6eb53cbfb83e935e442317af1fa37
{{- end -}}
{{- if eq .Values.version "7.1.0-1177103" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:972a9abbfe9793656354f42bf2c744bdab4695226b7fa009cff22b486a64809c
{{- end -}}
{{- if eq .Values.version "7.1.0-1177361" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:f80c27b355882bf06f08d6a33306cd5b1f723dd5952e12635e0b86d5e32b2a0f
{{- end -}}
{{- if eq .Values.version "7.1.0-1177383" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:db5482741aa0a573ea64c9a03d2b75b70127493c3c6d0448db18ebccc1d3673e
{{- end -}}
{{- if eq .Values.version "7.1.0-1178327" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:b5fe6cd2798451807f4fab34876bfa123ffc810933d380e53c741438fd7f63a4
{{- end -}}
{{- if eq .Values.version "7.1.0-1178435" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:9ddf6606e29ee22acaf32b908e88a057f02b8c82f9da50ca406fb861109c6dfd
{{- end -}}
{{- if eq .Values.version "7.1.0-1178537" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:22a7f1727aa627b53a6e437971451244b1940dcb61452821e5a0e238ed21ba93
{{- end -}}
{{- if eq .Values.version "7.1.0-1178549" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:8e7794d25af0a2205fa433e45a1d2faa07cfd2f8cafa4f706f351d582a60e32c
{{- end -}}
{{- if eq .Values.version "7.1.0-1178555" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:90b698f9e495a13d5b504271c5b23838a4b0d00d28e8340e1cc06e1c95c4b7a5
{{- end -}}
{{- if eq .Values.version "7.1.0-1178647" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server@sha256:ff58aa902844019a297394c47ab12134fb4696f6f86084946c724d46fc26fdce
{{- end -}}
{{- else -}}
{{- if eq .Values.version "7.0.0.4" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.0.0.4
{{- end -}}
{{- if eq .Values.version "7.0.0.4-xframe" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:1.0.0-xframe
{{- end -}}
{{- if eq .Values.version "7.0.0.4-rebranded-blueribbon" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.0.0.4-rebranded-blueribbon
{{- end -}}
{{- if eq .Values.version "7.0.0.4-iframe" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.0.0.4-iframe
{{- end -}}
{{- if eq .Values.version "7.1.0.int" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.1.0.int
{{- end -}}
{{- if eq .Values.version "7.1.0.int.2" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.1.0.int.2
{{- end -}}
{{- if eq .Values.version "7.1.0.int.3" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.1.0.int.3
{{- end -}}
{{- if eq .Values.version "7.1.0.int-loginpage" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.1.0.int-loginpage
{{- end -}}
{{- if eq .Values.version "7.1.0-1177092" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.1.0-1177092
{{- end -}}
{{- if eq .Values.version "7.1.0-1177103" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.1.0-1177103
{{- end -}}
{{- if eq .Values.version "7.1.0-1177361" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.1.0-1177361
{{- end -}}
{{- if eq .Values.version "7.1.0-1177383" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.1.0-1177383
{{- end -}}
{{- if eq .Values.version "7.1.0-1178327" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.1.0-1178327
{{- end -}}
{{- if eq .Values.version "7.1.0-1178435" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.1.0-1178435
{{- end -}}
{{- if eq .Values.version "7.1.0-1178537" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.1.0-1178537
{{- end -}}
{{- if eq .Values.version "7.1.0-1178549" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.1.0-1178549
{{- end -}}
{{- if eq .Values.version "7.1.0-1178555" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.1.0-1178555
{{- end -}}
{{- if eq .Values.version "7.1.0-1178647" -}}
  {{ .Values.global.imageRegistry }}/ibm-devops-build-server:7.1.0-1178647
{{- end -}}
{{- end -}}
{{- end -}}