#!/usr/bin/env bash

openssl-test() {
  [[ "$(openssl version)" = *"OpenSSL 1.1.1"* ]] || [[ "$(openssl version)" = *"OpenSSL 3"* ]]
}

openssl-assert() {
  if ! openssl-test; then
    echo -e "$ERROR openssl is not at the correct version$RESET"
    echo "Please install OpenSSL 1.1.1 or later" #20.04 LTS
    exit 1
  fi
}

workspace-make() {
  CERT_WORKSPACE_DIR=$(mktemp -d --suffix=-certs)
  touch "$CERT_WORKSPACE_DIR/index.txt"
  cat << EOF > "$CERT_WORKSPACE_DIR/index.txt.attr"
unique_subject = no
EOF

  openssl rand -hex 16 > "$CERT_WORKSPACE_DIR/serial"

  cat << EOF > "$CERT_WORKSPACE_DIR/ca.cfg"
[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca

[ req_distinguished_name ]

[v3_ca]
basicConstraints = CA:TRUE
keyUsage = keyCertSign

[ ca ]
default_ca = CA_default

[ CA_default ]
database       = $CERT_WORKSPACE_DIR/index.txt
serial         = $CERT_WORKSPACE_DIR/serial
new_certs_dir  = $CERT_WORKSPACE_DIR
policy         = policy_any
email_in_dn    = no
default_md     = sha256
default_days   = 397
copy_extensions = copy

[ policy_any ]
organizationName       = optional
commonName             = supplied
EOF

  cat << EOF > "$CERT_WORKSPACE_DIR/tls.cfg"
[ req ]
distinguished_name = req_distinguished_name
req_extensions = v3_req

[ req_distinguished_name ]

[v3_req]
basicConstraints = CA:FALSE
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $INGRESS_DOMAIN
DNS.2 = *.$INGRESS_DOMAIN
EOF
}

workspace-destroy() {
  rm -fr "$CERT_WORKSPACE_DIR"
}

cert-make() {
  secret_exists=0
  secret-has "$INGRESS_SECRET" || secret_exists=$?

  if [[ "$CERT_OVERWRITE" != "true" ]] && [ $secret_exists -eq 0 ]; then
    echo "For Ingress"
    echo 'Skip certificate creation - it already exists, to replace it re-run after doing:'
    echo "  $CMD_KUBECTL delete secret $INGRESS_SECRET -n $NAMESPACE"
  else
    workspace-make

    echo "For CA"
    if secret-has "$INGRESS_SECRET-ca"; then
      echo 'Skip CA creation - it already exists, to replace it re-run after doing:'
      echo "  $CMD_KUBECTL delete secret $INGRESS_SECRET-ca -n $NAMESPACE"
      secret-get "$INGRESS_SECRET-ca" tls.key > "$CERT_WORKSPACE_DIR/ca.key"
      secret-get "$INGRESS_SECRET-ca" tls.crt > "$CERT_WORKSPACE_DIR/ca.crt"
    else
      #create ca
      openssl req -x509 -newkey rsa:4096 -keyout "$CERT_WORKSPACE_DIR/ca.key" \
        -out "$CERT_WORKSPACE_DIR/ca.crt" -config "$CERT_WORKSPACE_DIR/ca.cfg" \
        -subj "/O=${INGRESS_DOMAIN:0:64}/OU=${INGRESS_DOMAIN:0:61} CA" -nodes \
        -days 3653 >/dev/null

      secret-create "$INGRESS_SECRET-ca" \
        "$CERT_WORKSPACE_DIR/ca.key" \
        "$CERT_WORKSPACE_DIR/ca.crt" \
        "$CERT_WORKSPACE_DIR/ca.crt"
    fi
    echo
    echo "For CSR"
    #create csr
    openssl req -newkey rsa:3072 -keyout "$CERT_WORKSPACE_DIR/tls.key" \
      -out "$CERT_WORKSPACE_DIR/tls.csr" -config "$CERT_WORKSPACE_DIR/tls.cfg" \
      -subj "/O=${INGRESS_DOMAIN:0:64}/CN=${INGRESS_DOMAIN:0:64}" -nodes >/dev/null
    echo
    echo "For Ingress"
    #create cert
    openssl ca -batch -in "$CERT_WORKSPACE_DIR/tls.csr" -keyfile "$CERT_WORKSPACE_DIR/ca.key" \
      -out "$CERT_WORKSPACE_DIR/tls.crt" -config "$CERT_WORKSPACE_DIR/ca.cfg" \
      -cert "$CERT_WORKSPACE_DIR/ca.crt" >/dev/null

    if [ $secret_exists -eq 0 ]; then
      secret_cmd=secret-update
    else
      secret_cmd=secret-create
    fi

    $secret_cmd "$INGRESS_SECRET" \
        "$CERT_WORKSPACE_DIR/tls.key" \
        "$CERT_WORKSPACE_DIR/tls.crt" \
        "$CERT_WORKSPACE_DIR/ca.crt"

    workspace-destroy
  fi
}

cert-show() {
  echo
  echo "Ingress certificate details:"
  openssl x509 -text -noout -certopt no_header,no_version,no_serial,no_signame,no_pubkey,no_sigdump,no_aux -in \
    <(secret-get "$INGRESS_SECRET" tls.crt)
  echo
  echo "Import the below Authority into your browser to avoid trust errors."
  echo "You may be required to confirm it should be used to identity websites."
  secret-get "$INGRESS_SECRET" ca.crt
}
