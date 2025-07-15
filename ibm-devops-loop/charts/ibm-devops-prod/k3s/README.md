# IBM DevOps Test Hub

IBM DevOps Test Hub brings together test data, test environments, and test runs and reports into a single, web-based browser for testers and non-testers. It is Kubernetes native and hence requires a cluster to run. If you do not have a cluster available we enable you to get started by providing scripts to provision a basic environment using K3s.

## Prerequisites





### Hardware

Either a bare metal or virtual machine which is dedicated solely for use by the product.

The product requires a minimum of:
* 16GiB memory
* 8 cpu
* 256GiB disk [Disk speed requirement for Kine/SQLite](https://docs.k3s.io/reference/resource-profiling#k3s-server-with-a-workload)

It is recommended that the machine has 32GiB memory.

Depending on workload considerably more resources could be required.

### Networking

* A static IP address.
* Wildcard DNS domain resolving to the machine running the product (eg. _wildcard.devops.myorg.com_ resolves to the static IP address)

If this DNS domain is not available the product will use: _ip-address.nip.io_. See [nip.io](https://nip.io/) for more details.

### Operating System

Either

* RedHat Enterprise Linux 8.10 or later
* Ubuntu Server LTS 22.04 or later

You should `Use The Entire Disk And Set Up LVM` using the ext4 or xfs filesystem. No SWAP or home partition should be created. If your organization requires application data to be stored in a separate partition, you may do so by creating a mount point at `/var/lib/rancher/k3s/storage/` with at least 128GiB capacity.

#### Install

* OpenSSH server
* [helm v3.17.3 or later](https://helm.sh/docs/intro/install/)

#### Do not Install

* Gnome Desktop (this causes high cpu load)

#### Cloud Services

When using RHEL, if nm-cloud-setup is enabled, it is required to be disabled:

```bash
systemctl disable nm-cloud-setup.service nm-cloud-setup.timer
reboot
```

#### Permission Denied errors

When installing on hardened systems, you might encounter the following error:
```
FATA[0000] open /etc/rancher/k3s/config.yaml.d: permission denied
```

This error typically occurs because the system's default umask is set to 027, which creates files and directories with restrictive permissions.

The umask setting of 022 should instead be configured system-wide in files like /etc/login.defs or /etc/profile.

Alternatively if this doesn’t work, add the user performing the installation to the root group:

```bash
sudo usermod -a -G root $USER
exit

```

After running this command, log back in for the group change to take effect.

#### Anti Virus / Malware

File scanning software (e.g anti virus / malware) may modify file metadata during scans. This can cause pod eviction due to changes presenting as ephemeral storage use that breach specified limits.

##### Symantec Endpoint Protection

Prevent Symantec Endpoint Protection from modifying file ctime: [source](https://knowledge.broadcom.com/external/article/158837/endpoint-protection-for-linux-ctime-is-c.html)
```bash
sudo /opt/Symantec/symantec_antivirus/symcfg add -k '\Symantec Endpoint Protection\AV' -v NoFileMod -d 1 -t REG_DWORD
```
Older versions of Symantec will still modify file ctime for file extensions `zip`, `jar`, `dat` and `sym`.

##### Others

An exception for the directory `/run/k3s/containerd/io.containerd.runtime.v2.task/k8s.io` must be created to prevent file scans from causing issues.



## Install

Fetch chart for install:
```bash
helm repo add ibm-helm https://raw.githubusercontent.com/IBM/charts/master/repo/ibm-helm --force-update
helm pull --untar ibm-helm/ibm-devops-prod --version 11.0.5
cd ibm-devops-prod
```



### Chart
```bash
NAMESPACE=devops-system
HELM_NAME=main

INGRESS_DOMAIN= # auto-detect wildcard domain
PASSWORD_SEED= # secure seed required to generate passwords - unrecoverable so keep it safe

ENTITLEMENT_REGISTRY_KEY= # from https://myibm.ibm.com/products-services/containerlibrary
RATIONAL_LICENSE_FILE=@rlks.localdomain

chmod +x k3s/*.sh

sudo \
  HELM_NAME=$HELM_NAME \
  INGRESS_DOMAIN=$INGRESS_DOMAIN \
  IMAGE_REGISTRY_PASSWORD=$ENTITLEMENT_REGISTRY_KEY \
  k3s/init.sh -n $NAMESPACE \
  --set-literal passwordSeed=$PASSWORD_SEED \
  --set signup=true \
  --set rationalLicenseKeyServer=$RATIONAL_LICENSE_FILE \
  --set license=true
```
* When the ingress domain is accessible to untrusted parties, `signup` must be set to `false`.
* The password seed is used to generate default passwords and should be stored securely. Its required again to restore from a backup.


### Troubleshooting

If the script errors, follow the suggestions it provides.
Other reasons the script can fail include:

* Slow connection speeds
* Insufficient cpu, memory or disk resources
* A misconfigured firewall is already enabled

Some issues can be solved by just re-running `k3s/init.sh`, but k3s logs can be viewed using `journalctl -u k3s`.

If in doubt run `kubectl get pods -A` to see what is not running followed by `kubectl describe pod` for more detail.
### Configuration

| Parameter                                      | Description | Default |
|------------------------------------------------|-------------|---------|
| `execution.ingress.hostPattern`                | Pattern used to generate hostnames so that running assets may be accessed via ingress. | PLATFORM specifc |
| `execution.nodePorts.enabled`                  | When `network.policy` is disabled, allow NodePorts to be used to access to running assets like virtual services. | true |
| `global.domain`                                | The web address to expose the product on. For example `192.168.0.100.nip.io` | REQUIRED |
| `global.ibmCertSecretName`                     | Optionally used to terminate TLS and when `ingress.cert.selfSigned`, is used to verify trust of loopback connections. | ingress |
| `global.ibmImagePullSecret`                    | The docker-registry secret to pull images from the `imageRegistry`. | '' |
| `global.ibmImagePullUsername`                  | Username to pull images from the `imageRegistry`. | 'cp' |
| `global.ibmImagePullPassword`                  | Password to pull images from the `imageRegistry`. | '' |
| `rationalLicenseKeyServer`                     | Where floating licenses are hosted to entitle use of the product. For example `@ip-address` | '' |
| `imageRegistry`                                | The location of container images to use. See [move-images](lib/airgap/move-images.sh) | cp.icr.io/cp |
| `ingress.cert.create`                          | Create an self-signed certificate matching the ingress domain if none exists in secret `global.ibmCertSecretName`. | true |
| `ingress.cert.selfSigned`                      | If the ingress domain certificate is not signed by a globally trusted CA. | PLATFORM specifc |
| `keycloak.truststoreFileHostnameVerificationPolicy` | HTTPS hostname cerificate verifcation policy. ANY (hostname is not verified), WILDCARD (allows wildcards in subdomain names) or STRICT (the Common Name (CN) must match the hostname exactly). | WILDCARD |
| `license`                                      | Confirmation that the EULA has been accepted. For example `true` | false |
| `networkPolicy.egress.cidrs`                   | Network ranges to allow access to. This does not include access to github.com where helm test resources are stored. | [ 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 ] |
| `networkPolicy.egress.enable`                  | When `network.policy` is enabled create a rule to narrow egress from the product. | false |
| `networkPolicy.enabled`                        | Deny other software, installed in the cluster, access to the product. | true |
| `passwordSeed`                                 | The seed used to generate all passwords. | REQUIRED |
| `postgresql.migrate.enabled`                   | Enable Postgresql version migration on start when coming from v10.5.3. Migration is disabled to avoid an unnecessary image pull. | false |
| `router.allowedOrigin`                         | A comma separated list of allowed origins for CORS. For example `*.domain.com,*.test.com,10.10.*.*`  | '' |
| `results.jaegerAgent`                          | The name of the service/host that execution engines write traces to. | '' |
| `results.jaegerDashboard`                      | The URL for where traces may be opened in a browser. | '' |
| `signup`                                       | Allow users to create their own accounts. (Setting also in realm under Login > User registration) | false |

## Upgrade

Upgrading from releases prior to v11.0.3 is not support - for older versions first upgrade to an intermediate release.

Before performing your upgrade RabbitMQ flags must be enabled on a running install:

```bash
kubectl exec -n $NAMESPACE $HELM_NAME-rabbitmq-0 -- rabbitmqctl enable_feature_flag all

```

If you are restoring from a quiesced snapshot, meaning no instance is running, you can instead delete the RabbitMQ data before installing:

```bash
kubectl delete pvc -n $NAMESPACE data-$HELM_NAME-rabbitmq-0

```

Before performing your upgrade backup your user data.

```bash
sudo k3s/backup.sh create-pvc-links # only if the is the first time a backup has been made
k3s-killall.sh # stops the cluster
sudo k3s/backup.sh create ~/backup-devops-$(date -u +%Y%m%d).tar.gz
```
Once you have the backup, you should completely remove the existing install.  This is done by running:
```bash
sudo k3s/wipe.sh --confirm
```


Install the product as [above](#chart).


Once the installation has completed (with all pods running), run the following to restore the data:
```bash
sudo k3s/backup.sh create-pvc-links -v /var/lib/rancher/k3s/backup-devops-remap
k3s-killall.sh
sudo k3s/backup.sh restore -v /var/lib/rancher/k3s/backup-devops-remap \
       ~/backup-devops-$(date -u +%Y%m%d).tar.gz

sudo systemctl start k3s
echo "wait for key pod to start..."; sleep 45
kubectl wait --for=condition=Ready pod/$HELM_NAME-ssocloak-0 -n $NAMESPACE --timeout 120s
helm upgrade $HELM_NAME . -n $NAMESPACE --reuse-values
```
Note: Until the full procedure is completed some pods may be in an Unknown state.






#### Data Migration

RabbitMQ will not run when migrating data to a different namespace. To enable re-initialization during install either:

- Skip the backup of RabbitMQ data: [`velero.io/exclude-from-backup=true`](https://velero.io/docs/v1.14/resource-filtering/#veleroioexclude-from-backuptrue)

```bash
kubectl label pvc -n $NAMESPACE data-$HELM_NAME-rabbitmq-0 velero.io/exclude-from-backup=true
```

- Delete the data post restore:

```bash
kubectl delete pvc -n $NAMESPACE data-$HELM_NAME-rabbitmq-0
```

## Verification

You can verify that the environment has completed startup with:
```bash
watch kubectl get pods -A
```
All the pods should change to a status of either Running or Complete.
```bash
bash lib/test/helm-diag.sh $HELM_NAME -n $NAMESPACE
```
## Uninstall



To delete _EVERYTHING_, including user data
```bash
cd ibm-devops-prod
sudo k3s/wipe.sh --confirm
```
## Security Considerations

### Ingress

#### Firewall

The product loops back some requests via the ingress controller. It this is blocked by a firewall some pods will fail to transition to Running without it.

##### RedHat Enterprise Linux

When installing firewall changes are automatically made to enable components to successfully start.

##### Ubuntu Server

When installing no firewall changes are made. If _ufw_ is enabled then `k3s/ufw.sh` can be used to enable external acccess to the product.

#### Trust of generated self signed certificate

When necessary the product generates a CA and certificate to terminate TLS. To fetch the generated CA so that it can be injected into other softwares trust stores, see the notes from:
```bash
helm status $HELM_NAME -n $NAMESPACE
```
#### Providing an new certificate

The helm install will automatically create a self-signed certificate to match the ingress domain. If you have a certificate signed by a CA you can use it instead by creating a secret of the following form before performing the install:
```bash
kubectl create namespace $NAMESPACE
kubectl create secret generic ingress -n $NAMESPACE \
  --type=kubernetes.io/tls \
  --from-file=ca.crt="./ca.crt" \
  --from-file=tls.crt="./tls.crt" \
  --from-file=tls.key="./tls.key"
```
Where tls.key is your private key, tls.crt is the certificate returned by your CA and ca.crt is the certificate of your CA (which signed your certificate). All these files are expected to be in PEM format. Note: the structure of the secret is consistent with those created by [cert-manager](https://cert-manager.io/docs/)

If the product is already installed. The secret can be replaced, but all the pods must be deleted or restarted manually to take effect.

#### Internal certificate expiry

After 365 days an internal certificate expires, causing the product to stop working. To resolve this:
```bash
kubectl delete secret emissary-ingress-webhook-ca -n emissary-system
kubectl delete pods -lapp.kubernetes.io/name=emissary-apiext -n emissary-system
```


### Trust of external self signed endpoints

The product only trusts certificates signed by recognized CAs. To trust additional CAs, for example your internal corporate CA, you must create a secret containing the additional CAs you wish to trust.

The certificate must be in PEM format and have a `.crt` extension.
```bash
kubectl create secret generic -n $NAMESPACE usercerts --from-file=corp-ca.crt
```
Once created you need to restart pods that mount it for the additional CA to be trusted. Pods that mount this secret can be listed by running:
```bash
kubectl get pod -n $NAMESPACE -o json | jq -r \
  '.items[] | select(.spec.volumes[]?.secret.secretName == "usercerts") | .metadata.name'
```
They can be forced to restart by deleting them.
```bash
kubectl delete pod $HELM_NAME-tam-0 -n $NAMESPACE
```
The log will show the additional CAs if successfully added.
```bash
kubectl logs $HELM_NAME-tam-0 -n $NAMESPACE -c trust-store
```
Further certificates can be added. Note that getting certificates with openssl without verification makes you vulnerable to man-in-the-middle attacks.
```bash
openssl s_client -connect cncf.io:443 -servername cncf.io </dev/null \
  | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > cncf.crt

kubectl patch secret usercerts -n $NAMESPACE --type=json \
  -p='[{"op":"replace","path":"/data/cncf.crt","value":"'$(base64 -w0 cncf.crt)'"}]'
```
The secret is not included in the normal backup scheme. You should manually backup the secret containing the additional CAs if you consider it valuable.

### Egress

In the default configuration, no egress rules are created to restrict the endpoints that the product can connect to. This enables the product to be deployed easily, without knowledge of the system under test. In environments with stricter access requirements, `networkPolicy.egress.enable` can be enabled to restrict traffic to `networkPolicy.egress.cidrs` (which defaults to private addresses defined in RFC1918). Note: With this egress policy applied, `helm test` is expected to fail due to resources used being hosted on github.com.

### Dynamic workload

To scale test asset execution the product creates kubernetes resources dynamically. To review the permissions required to do this consult the execution [role](templates/execution/role.yaml) with its [binding](templates/execution/rolebinding.yaml).

When the resources are created a label is applied so they may be tracked:
```bash
kubectl get all,cm,secret -lapp.kubernetes.io/managed-by=$HELM_NAME.$NAMESPACE -n $NAMESPACE
```
These resources are deleted 24 hours after the execution completes.

It is possible for users to request executions that exceed the resources available in the cluster. In such cases execution pods can be left Pending or Evicted. To ensure that only the dynamic workload is affected, meaning that critical services are not affected, appropriate priorityClasses need to be used within the cluster so that critical services are given priority by the scheduler.

As general guidance if your cluster has a fixed number of nodes; configure `execution.priorityClassName` with a class that has a [negative](https://kubernetes.io/blog/2019/04/16/pod-priority-and-preemption-in-kubernetes/) priority. This makes the dynamic workload the least important in the cluster thereby protecting critical services. If your cluster autoscales a negative priority can not be used since the autoscaler will not scale the cluster to meet demand from pods with a negative priority. In such cases setting a default priorityClass in the cluster with a high value for critical services is recommended with a different, lower, non-negative class for the dynamic workload using `execution.priorityClassName`. Further information can be found in the configuration section.

### Credential changes

Passwords are generated from the provided seed and stored in secrets when installing the software. These passwords can be changed in bulk by changing the seed used in the helm command, or individually by directly changing the value stored in the secret. However, for the values to become live you must run:
```bash
bash lib/migrate/reconcile-secrets.sh
```
User defined secrets used within the software are encrypted. The encryption key is also generated as above and held in a secret. It is not possible to re-encrypt these secrets without the original seed used to encrypt them. To re-encrypt the secrets, follow the steps given when running the script referenced above.

This methods should also be used when restoring a backup made where different secrets were in use.

## Limitations

* `helm rollback` is not currently supported. Move back to a previous release by restoring a backup taken before the upgrade.
* `helm upgrade` is only supported for specific versions. See [Upgrade](#upgrade) for details.
* It is not currently possible to edit test assets. This must be done in DevOps Test Workbench.
* In each namespace, only one instance of the product can be installed.
* The replica count configuration enables a maximum of 50 active concurrent users. This configuration can not be changed.


### Supported Environments

On K3s, the product is only supported in a single node configuration.

