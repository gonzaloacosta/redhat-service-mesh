# Red Hat Service Mesh - Homework

Red Hat Service Mesh Homework for Adv Red Hat Service Mesh Course

* *Student*: Gonzalo Acosta
* *Company*: Semperti [Red Hat Partner]
* *Email*: <gonzalo.acosta@semperti.com>

### 1. POC Environment

*IMPORTANT!!! Expiration Lab 10/01/20 11:47 EDT* 

* API Server

```
$ oc whoami --show-server
https://api.cluster-5018.5018.sandbox559.opentlc.com:6443
```

* Web Console

```
$ oc whoami --show-console
https://console-openshift-console.apps.cluster-5018.5018.sandbox559.opentlc.com
```

* Users

```
Admin User: admin
Admin Password: r3dh4t1!

Mesh-admin User: user1
Mesh-admin Password: r3dh4t1!
```

* Lab Red Hat Service Mesh Fundation, Openshift Version

```
$ oc version
Client Version: 4.3.3
Server Version: 4.3.3
Kubernetes Version: v1.16.2
```

### 2. Prereq

- Openshift Cluster Up
- Openshift Client Work

```bash
git clone https://github.com/gonzaloacosta/redhat-service-mesh
chmod +x scripts/*.sh
```

### 3. Business Application

Install Bookinfo Application

```bash
sh ./scripts/1-bookinfo-deploy.sh
```

### 4. OpenShift Service Mesh Operator and Control Plane

All the operators was installed from Official sources except Red Hat Service Mesh Operator

[Installing OSSM](https://docs.openshift.com/container-platform/4.3/service_mesh/service_mesh_install/installing-ossm.html)

* Installing the Elasticsearch Operator
* Installing the Jaeger Operator
* Installing the Kiali Operator

* Installing the Red Hat OpenShift Service Mesh Operator

```bash
$ sh ./scripts/2-service-mesh-operator-deploy.sh
```
* Installing Control Plane

```bash
$ sh ./scripts/3-redhat-service-mesh-controlplane-deploy.sh
```

### 5. ServiceMeshMemberRoll

* Install a ServiceMeshMemberRoll resource with bookinfo as its only member.

```bash
$ sh ./scripts/4-service-mesh-member-roll.sh
```

* Inject envoy to bookinfo deployments

```bash
$ sh ./scripts/5-inject-envoy-proxy.sh
```

### 6. mTLS Security

* Create gateway and certs

```bash
$ sh ./scritps/6-certificates-istio-ingressgateway.sh
```
* All Red Hat Service Mesh Resources for bookinfo
  * Gateways
  * VirtualServices
  * DestinationRules
  * Policy

```bash
$ sh ./7-istio-resources-bookinfo.sh
```

* Grant permission to user1 for mesh-admin

```bash
$ sh ./scripts/8-grant-permission-user1.sh
```

### Check functionality

```bash
export GATEWAY_URL=$(oc -n bookretail-istio-system get route productpage-gateway -o jsonpath='{.spec.host}')
curl -kv -o /dev/null -s -w "%{http_code}\n" https://$GATEWAY_URL/productpage
200
```

### Run continuous probes

```bash
while (true) ; do curl -kv -o /dev/null -s -w "%{http_code}\n" https://$GATEWAY_URL/productpage ; sleep .1 ; done
```




















