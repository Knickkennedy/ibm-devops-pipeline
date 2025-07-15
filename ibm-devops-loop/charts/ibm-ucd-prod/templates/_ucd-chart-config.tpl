{{/*
license  parameter must be set to true
*/}}
{{- define "{{ .Chart.Name }}.licenseValidate" -}}
  {{ $license := .Values.license.accept }}
  {{- if $license  -}}
    true
  {{- end -}}
{{- end -}}

{{- define "{{ .Chart.Name }}.imagePath" -}}
{{- if or (eq .Values.global.imageRegistry "cp.icr.io/cp") (not .Values.global.imageRegistry) -}}
  cp.icr.io/cp
{{- else if and (.Values.global.imageRegistry) (.Values.image.repository) -}}
  {{ .Values.global.imageRegistry }}/{{ .Values.image.repository }}
{{- else if (.Values.global.imageRegistry) -}}
  {{ .Values.global.imageRegistry }}
{{- else -}}
  cp.icr.io/cp
{{- end -}}
{{- end -}}

{{/* Determine which image to use given the product version.  */}}
{{/* Values.version can be an imagespec to allow registries other than IBM ER */}}
{{- define "{{ .Chart.Name }}.imageSpec" -}}
{{- $imagePathName := include "{{ .Chart.Name }}.imagePath" . | trim -}}
{{- if eq .Values.version "8.1.2.0" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:34aad9c6e56eaf0a5ac7e9a47bed7f7c83ad127b8026406fae0179bf09b6e2bc
{{- else if eq .Values.version "8.1.1.0" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:dd2c5831d970b113a030d53497037c10310c646c3a21ff7c3c911e18b45fbab3
{{- else if eq .Values.version "8.1.0.1" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:b51f7d1c5fc1fc1afa1ab8d45f9c7ffe6f74deeb4c8278f5ea94416c218e6dce
{{- else if eq .Values.version "8.1.0.0" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:19d786fab318319312070008638d37ae9ceca2c1001068f244b0729fa1721a67
{{- else if eq .Values.version "8.0.1.7" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:614e48e28a02dff71efd7d368c5df8ba008503bfb23e310a441a9c3fd11e5efc
{{- else if eq .Values.version "8.0.1.6" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:b5496aaeca2b68331e8d408b6f546b6bf314a9bba593fa31f28cc97aeb0e0331
{{- else if eq .Values.version "8.0.1.5" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:6a8fe742f364ea167bb22841f4346a3899034447391cb59fff711ba9fbd86c25
{{- else if eq .Values.version "8.0.1.4" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:60c059a571cc1b93d752b5a0ce61c40f93698e605e271a13ee293e50a2af943e
{{- else if eq .Values.version "8.0.1.3" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:9a13a0a9b7ba93ce7949b2495a627f4ce709dc9bd6ba79360644f7e1ea2060d5
{{- else if eq .Values.version "8.0.1.2" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:3e965d9b41d3ef1b492853e15c95f2a02094f71f31493514f29f50448746fcf3
{{- else if eq .Values.version "8.0.1.1" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:8819d318b5bdacc2dafdf3e4e9020496c2040dced0b20199ac8b0dcf0518f43a
{{- else if eq .Values.version "8.0.1.0" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:c1eca3567501049ae1145788874727de146431e72b9f9f4ec039ead804584fa2
{{- else if eq .Values.version "8.0.0.1" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:1cafd54dc874343751a68f53f3d78b8cc4d38a93e4d4815b81795ebd1c785e27
{{- else if eq .Values.version "8.0.0.0" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:428562d18cc417149887e8aa4bb3cd16501c05998ffbdb2696f8089d32191660
{{- else if eq .Values.version "7.3.2.12" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:2a96a0339883f1bc7c0b99c3caa6d2719b5a9f305d4ae50035e9eaa79a65fe88
{{- else if eq .Values.version "7.3.2.11" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:741503355eeb6b88c4eaac19d1375a09ee8de25166b8c6da3540c22cc8eb2200
{{- else if eq .Values.version "7.3.2.10" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:51c6bebc154ff76e6ce06a10cff17c2436b26d847d6af92e401513d67738fbce
{{- else if eq .Values.version "7.3.2.9" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:dd3022cc72a045df9e7751bef4b3b4d0f89a39397d123441367b4229119521b4
{{- else if eq .Values.version "7.3.2.8" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:09a2dd2491a74dc85df0dd62d1806af6f9414efc8658fe3a22f4150d33a5012f
{{- else if eq .Values.version "7.3.2.7" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:6dfb56ce66d8283a5631750277b0a842ccf10883436c4cff54e5b7c003a13bf5
{{- else if eq .Values.version "7.3.2.6" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:0b4dec751c5d93cfd006f06dbc5078b9bb74b5fa523d8c8bade5bd267d39fbd1
{{- else if eq .Values.version "7.3.2.5" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:4f398304d1d470e9fc4f2c41aff990c4e65acd4b341a38e8455bdf90d186bf6e
{{- else if eq .Values.version "7.3.2.4" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:5fa682b124d5a3066890ccbcf7442c3ee0e1567d1c830c3eb8d188f86d14d0d4
{{- else if eq .Values.version "7.3.2.3" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:de50b9eb93e05743c55c52abd1ce6559a0e4d550480e8bc6f67bf2cff7e5002a
{{- else if eq .Values.version "7.3.2.2" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:2b5c07073b3fb812867928f6ac8d9f09c9fb65ac59808d20ef0618ab969c12d3
{{- else if eq .Values.version "7.3.2.1" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:4ef119fcb2f7610c3fa86880204c60e64012197cae5b60800fd447f109e60a4c
{{- else if eq .Values.version "7.3.2.0" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:e066d8582d8db5bc379d37113d2b19bfe5bbaefc5853bbfe3cb52fade02efcc2
{{- else if eq .Values.version "7.3.1.1" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:e7d25b2f76a72018c62f7c8c87b7e96a965cf07e0db317d69030bee187ac8ef7
{{- else if eq .Values.version "7.3.1.0" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:8115a493365bb979c7d3231c102611cd2e2530d4f61d7961e239f416cd2e0912
{{- else if eq .Values.version "7.3.0.1" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:79cf716ec428889436cab9eeda3bb8c5a0b01d6c1911f0c976e915178e3d8fce
{{- else if eq .Values.version "7.3.0.0" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:545c86b0986a0d07d95acd1193626350e1a1eaa068517de24c7cf8d96cd08770
{{- else if eq .Values.version "7.2.3.17" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:8f038330da8977edf8f47f7353a0d0b7a0260440dc00e845849346426e366b68
{{- else if eq .Values.version "7.2.3.16" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:d1c286d89175ee4e4ece8e9662ff6ecdfb60b8b0c94cf2ab644f97e5c4fa7493
{{- else if eq .Values.version "7.2.3.15" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:c4d2e1b35f634aaec2c7889bdbc54118e151c1f01e171f7400e6676de2792cbb
{{- else if eq .Values.version "7.2.3.14" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:1173730178eab9933233a36783fd287ffa70a4eaeef494a4bcef4a42169a397e
{{- else if eq .Values.version "7.2.3.13" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:bef1c0bd707e7d8437e2efff371168042c51debeb175e258c2b13a581e4722d6
{{- else if eq .Values.version "7.2.3.12" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:54c378e771a3ee51e48e15ab269fcaef3f53e9d78eb87752d3d3472ec30ac76a
{{- else if eq .Values.version "7.2.3.11" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:b7238b31f99dd9fcb0de26cf9f77778c28dbfe4fd734007aab3d7b7f58bb69ea
{{- else if eq .Values.version "7.2.3.10" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:be116c2963a4f4d18bf34cd13e2ce87212eef2b345a676805471c5d7854600a3
{{- else if eq .Values.version "7.2.3.9" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:d0ad2bb32845f814696f153b6de088ff4c179b6d00dbcce7046e04d771acfb5b
{{- else if eq .Values.version "7.2.3.8" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:4901dc82838109a390298dd8df0e1512d629251c305dcf7cb9f99f4b40fe9474
{{- else if eq .Values.version "7.2.3.7" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:63aebc3f18981983ef9f50a4045a22b549779932d5356178c2680902b03849ae
{{- else if eq .Values.version "7.2.3.6" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:c1dd920ba747d2091d7a70e90c4f39981bb3c54663f56f869eeda7b6f8d3a714
{{- else if eq .Values.version "7.2.3.5" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:0e8a2a751d64ca87cc3c2c2568ef1a699c91b6d0c43744339171e61a7e2673df
{{- else if eq .Values.version "7.2.3.4" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:15cdb4926f4f5cd8b1c7268e89b61ec5cfaf8a624478525d55364f67462359c9
{{- else if eq .Values.version "7.2.3.3" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:ff9418927be668c0198ae88814458336b6fc0c5f2c310eee075de57df9722f5f
{{- else if eq .Values.version "7.2.3.2" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:67c9ce528f7b259fcb71670c861fdcaa60c1bf3afc660abf4ad94e9d0ca1067f
{{- else if eq .Values.version "7.2.3.1.ifix01" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:c3251d5d41118f3f8162b1ce9c5e2a47e1f590337a4f3f08c4aa874c98ec3e38
{{- else if eq .Values.version "7.2.3.0.ifix01" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:22cd892983f3ea9d70a9d9683974c97eb2f495e80d9ed8f2f99d30799026590d
{{- else if eq .Values.version "7.2.2.1" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:3fccd6bef1154519cea255964cae68b3a2e4151796dc542ad8f1c7d59b068e1c
{{- else if eq .Values.version "7.2.2.0" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:df8916fb179e4d5ef073c6c63558053149ff19d175727cf6805226022cf96483
{{- else if eq .Values.version "7.2.1.2" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:50576f600fbd95903cea6dae8916ceb0a70412397cd291ef950740e60201b843
{{- else if eq .Values.version "7.2.1.1" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:6dc51e00ef35ec5afaf4a17bf8bb5a69b906d286e6e05becf0a0efa3b5a7ea5f
{{- else if eq .Values.version "7.1.2.24" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:1391646fc3b011e272b3516d95f1148b0c5234be2af83a47b5978fbf8d50b620
{{- else if eq .Values.version "7.1.2.23" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:8858f86ebaaf9c51d1ee7e90acb038a85b4fe6270a92ab72f37345ff1e9f2dbd
{{- else if eq .Values.version "7.1.2.22" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:dd72aaa4957198f38e1b8bf15a3ffd2c656c01829aea4cd8510fabb5a1ce232a
{{- else if eq .Values.version "7.1.2.21" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:dcdb47b8affc9357fa890c967b8f41eaad0bebd4816b87da129cd24f1d546558
{{- else if eq .Values.version "7.1.2.20" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:abd1b3f010939d6a6c6aff9690b516d33bf08f9c6bbd162533ca896530545f94
{{- else if eq .Values.version "7.1.2.19" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:6ac752cd3c082de1ba0e7e53beb5b2b4b9a2fa653d6430c019e5541e5db2665c
{{- else if eq .Values.version "7.1.2.18" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:ceaeb24a0fef26a9503ec75bd8f9f3cc8da806f6f52f3883c0c59eb49a85250e
{{- else if eq .Values.version "7.1.2.17" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:631412d9c140619968fee0cf1c10ba503726b218cf8cd8a0aef0a24d5aea2f8a
{{- else if eq .Values.version "7.1.2.16" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:6eb77012faf7e3224f76a4f869af71a454bf141aacd01f2f4c7783476a526ff9
{{- else if eq .Values.version "7.1.2.15" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:a85946f47b99a7b07c983f7f87dab070e03e2986296858a12e1c49cdc95c5d64
{{- else if eq .Values.version "7.1.2.14" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:e4d8b2228e22c92919812c30de2896c47445bb5381c21359ac409b58977c8993
{{- else if eq .Values.version "7.1.2.13" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:dfc3fe23679c9dc2a4ed9c21001e2a3752d1bfb421f00626e821e6013df80603
{{- else if eq .Values.version "7.1.2.12" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:b04652e2e78fa1ba3c081aa3a9e67ba08a692a3bfafc7a029dfc653b745b9dc1
{{- else if eq .Values.version "7.1.2.11" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:151f4eb083d72eac39b9f5484a567df2f7216842190ea86462324da84c9ce166
{{- else if eq .Values.version "7.1.2.10" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:41400bb291a347d18621cdd5ff9fa21e5cee4ee64bbc805d6750e66a4bc72aeb
{{- else if eq .Values.version "7.1.2.9" -}}
  {{ $imagePathName }}/ibm-ucds@sha256:a7e133090c922d6ca3f6327ad1f2fcb8303aa27ed8941cf0f3e26dbdc6da1ba6
{{- else -}}
  {{ .Values.version }}
{{- end -}}
{{- end -}}

{{- define "{{ .Chart.Name }}.extLibConfigName" -}}
{{- if .Values.extLibVolume.configMapName -}}
  {{ .Values.extLibVolume.configMapName }}
{{- else if .Values.database.fetchDriver -}}
  {{ .Release.Name }}-extlibvolume-jdbc
{{- end -}}
{{- end -}}

{{- define "{{ .Chart.Name }}.externalImagePrefix" -}}
{{- if and (.Values.global.externalImageRegistry) (.Values.image.repository) -}}
  {{- printf "%s/%s/" .Values.global.externalImageRegistry .Values.image.repository -}}
{{- else if (.Values.global.externalImageRegistry) -}}
  {{- printf "%s/" .Values.global.externalImageRegistry -}}
{{- end -}}
{{- end -}}
