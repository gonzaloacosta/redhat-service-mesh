# Red Hat Service Mesh - Homework

Red Hat Service Mesh Homework for Adv Red Hat Service Mesh Course

* *Student*: Gonzalo Acosta
* *Company*: Semperti [Red Hat Partner]
* *Email*: <gonzalo.acosta@semperti.com>

## 2. POC Environment

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

## 3. Business Application

Install Bookinfo Application

```bash
oc new-project bookinfo
oc apply -f https://raw.githubusercontent.com/istio/istio/1.4.0/samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo
oc expose service productpage
echo -en "\n$(oc get route productpage --template '{{ .spec.host }}')\n"
```

## 4. OpenShift Service Mesh Operator and Control Plane

All the operators was installed from Official sources except Red Hat Service Mesh Operator

[Installing OSSM](https://docs.openshift.com/container-platform/4.3/service_mesh/service_mesh_install/installing-ossm.html)

* Installing the Elasticsearch Operator
* Installing the Jaeger Operator
* Installing the Kiali Operator

### 4.2 Installing the Red Hat OpenShift Service Mesh Operator

```bash
mkdir {scripts,manifest,cert}
```

```bash
cat << EOF > ./scripts/2-service-mesh-operator-deploy.sh
#!/bin/bash
# Deploy Red Hat Service Mesh Operator

export SM_OP_NS=istio-operator

echo "Create project $SM_OP_NS for Red Hat Service Mesh Operator.."

echo "kind: Project
apiVersion: project.openshift.io/v1
metadata:
  name: $SM_OP_NS
  annotations:
    openshift.io/display-name: 'Red Hat Service Mesh Operator'" | oc create -f -


echo "Create operator groups in $SM_OP_NS..."

echo "apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: service-mesh-operators
spec: {}" | oc create -f - -n $SM_OP_NS


echo "Create suscription Red Hat Service Mesh Operator..."
echo "apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: servicemeshoperator
spec:
  channel: stable
  installPlanApproval: Automatic
  name: servicemeshoperator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: servicemeshoperator.v1.1.8" | oc create -f - -n $SM_OP_NS


echo "Wait until service mesh opertor is ready"
while (true); do
  REPLICAS_READY=$(oc get deployment istio-operator -n $SM_OP_NS -o jsonpath='{.status.readyReplicas}')
  if [[ ${REPLICAS_READY} -eq 1 ]] ; then
      echo "Operator is ready!"
      break
  else
      echo "Waiting for replicas ready..."
  fi
  sleep 10
done
EOF
```

```
chmod +x service-mesh-operator-deploy.sh
./service-mesh-operator-deploy.sh
```

### 4.3 Installing Control Plane

```bash
cat << EOF > 3-redhat-service-mesh-controlplane-deploy.sh
#!/bin/bash
# Deploy Control Plane

export SM_CP_NS=bookretail-istio-system

echo "Create namespaces for control plane.."

echo "kind: Project
apiVersion: project.openshift.io/v1
metadata:
  name: $SM_CP_NS
  annotations:
    openshift.io/display-name: 'Service Mesh System'" | oc create -f -

echo "Check the CSV is installed Succesful.."

while (true); do
  STATUS_SUCCEECED=$(oc get csv -n $SM_CP_NS servicemeshoperator.v1.1.8 -o jsonpath='{.status.phase}')
  if [[ ${STATUS_SUCCEECED} -eq "Succeeded" ]] ; then
      echo "Operator is ready in namespace $SM_CP_NS!"
      break
  else
      echo "Waiting for replicas ready..."
  fi
  sleep 10
done

while (true); do
  STATUS_SUCCEECED=$(oc get csv -n $SM_CP_NS kiali-operator.v1.12.15 -o jsonpath='{.status.phase}')
  if [[ ${STATUS_SUCCEECED} -eq "Succeeded" ]] ; then
      echo "Operator Kiali is ready in namespace $SM_CP_NS!"
      break
  else
      echo "Waiting for replicas ready..."
  fi
  sleep 10
done

echo "Deploy Red Hat Sercice Mesh Control Plane in namespace $SM_CP_NS"

echo "apiVersion: maistra.io/v1
kind: ServiceMeshControlPlane
metadata:
  name: full-install
spec:
  threeScale:
    enabled: false

  istio:
    global:
      mtls:
        enabled: false
        auto: false
      disablePolicyChecks: true
      proxy:
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 128Mi

    gateways:
      istio-egressgateway:
        autoscaleEnabled: false
      istio-ingressgateway:
        autoscaleEnabled: false
        ior_enabled: false

    mixer:
      policy:
        autoscaleEnabled: false

      telemetry:
        autoscaleEnabled: false
        resources:
          requests:
            cpu: 100m
            memory: 1G
          limits:
            cpu: 500m
            memory: 4G

    pilot:
      autoscaleEnabled: false
      traceSampling: 100.0

    kiali.enabled: true

    kiali:
      dashboard:
        user: admin
        passphrase: redhat

    tracing:
      enabled: true" | oc create -f - -n $SM_CP_NS


echo "Check control plane is deployed"


while (true); do
  REPLICAS_READY=$(oc get deployment -n $SM_CP_NS istio-pilot -o jsonpath='{.status.readyReplicas}')
  if [[ ${REPLICAS_READY} -eq 1 ]] ; then
      echo "Operator is ready!"
      break
  else
      echo "Waiting for replicas ready..."
  fi
  sleep 10
done
EOF
```

```
chmod +x ./scripts/3-redhat-service-mesh-controlplane-deploy.sh
./scritps/3-redhat-service-mesh-controlplane-deploy.sh
```

## 5. ServiceMeshMemberRoll


### 5.1 Install a ServiceMeshMemberRoll resource with bookinfo as its only member.

```bash
cat << EOF > ./scripts/4-service-mesh-member-roll.sh
#!/bin/bash
# Add namespace to mesh

echo "apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
spec:
  members:
  - bookinfo" | oc create -f - -n $SM_CP_NS

while (true); do
  BOOKINFO_NS_READY=$(oc get project -l kiali.io/member-of=$SM_CP_NS,maistra.io/member-of=$SM_CP_NS | awk '/bookinfo/ { print "OK" }')
  if [[ ${BOOKINFO_NS_READY} -eq "OK" ]] ; then
      echo "Bookinfo namespace was included to service mesh!!"
      break
  else
      echo "Waiting for include namespace to mesh..."
  fi
  sleep 10
done
EOF 
```

```
chmod +x ./scripts/4-service-mesh-member-roll.sh
./scripts/4-service-mesh-member-roll.sh
```

### 5.2 Inject envoy to bookinfo deployments

```bash
cat << EOF > ./scripts/5-inject-envoy-proxy.sh
#!/bin/bash
# Inject Envoy Proxy
echo "Patch all deployment into bookinfo namespaces..."
echo ""
for i in $(oc get deployment -n bookinfo | grep -v NAME | awk '{print $1}')
do
  oc patch deployment/$i -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n bookinfo
done
sleep 60
for POD in $(oc get pods -n bookinfo  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}')
do
    oc get pod $POD  -n bookinfo -o jsonpath='{.metadata.name}{":\t\t"}{.spec.containers[*].name}{"\n"}'
done
EOF
```

```
chmod +x ./scripts/5-inject-envoy-proxy.sh
./scripts/5-inject-envoy-proxy.sh
```

## 6. mTLS Security

### Create gateway and certs

```bash
cat << EOF > ./scripts/6-certificates-istio-ingressgateway.sh
#!/bin/bash
# Configure mTLS in bookinfo service mesh

export APP=bookinfo
export SM_CP_NS=bookretail-istio-system
export SUBDOMAIN_BASE=cluster-5018.5018.sandbox559.opentlc.com

echo "Create certificates selft signed for ingress gateways..."
echo ""

echo "
[ req ]
req_extensions     = req_ext
distinguished_name = req_distinguished_name
prompt             = no

[req_distinguished_name]
commonName=$APP.apps.$SUBDOMAIN_BASE

[req_ext]
subjectAltName   = @alt_names

[alt_names]
DNS.1  = $APP.apps.$SUBDOMAIN_BASE
DNS.2  = *.$APP.apps.$SUBDOMAIN_BASE
" > cert.cfg

openssl req -x509 -config cert.cfg -extensions req_ext -nodes -days 730 -newkey rsa:2048 -sha256 -keyout tls.key -out tls.crt

echo "Create secrets for istio-ingressgateway..."
oc create secret tls istio-ingressgateway-certs --cert tls.crt --key tls.key -n $SM_CP_NS

echo ""
echo "Patch deployment istio-ingressgateway.."
oc patch deployment istio-ingressgateway -p '{"spec":{"template":{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt": "'`date +%FT%T%z`'"}}}}}' -n $SM_CP_NS
EOF
```

```bash
chmod +x ./scripts/6-certificates-istio-ingressgateway.sh
./scritps/6-certificates-istio-ingressgateway.sh
```

### Product Page

```bash

cat << EOF > ./scritps/7-istio-resources-bookinfo.sh
#!/bin/bash

# Apply Istio Resources for bookinfo with mTLS STRICT Policy

export SM_CP_NS=bookretail-istio-system
export MANIFEST=./manifest/
mkdir -p $MANIFEST

# Product Page
######################################################################################

echo ""
echo ">> BookInfo - Product Pace"
echo ""
echo "> Configure ingress gateway for bookinfo"

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-wildcard-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      privateKey: /etc/istio/ingressgateway-certs/tls.key
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
    hosts:
    - productpage.bookinfo.apps.cluster-5018.5018.sandbox559.opentlc.com" > $MANIFEST/bookinfo-wildcard-gateway.yaml

oc create -f $MANIFEST/bookinfo-wildcard-gateway.yaml -n $SM_CP_NS


echo "> Adding command-base readiness and liveness probe to bookinfo..."

for i in $(oc get deploy -n bookinfo | awk '/\-v/ {print $1}')
do
  oc set probe deploy -n bookinfo $i --liveness -- echo ok
  oc set probe deploy -n bookinfo $i --readiness -- echo ok
done

echo "> Create Policy"

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: productpage-policy-mtls
spec:
  peers:
  - mtls:
      mode: STRICT
  targets:
  - name: productpage" > $MANIFEST/productpage-policy-mtls.yaml

oc create -n bookinfo -f $MANIFEST/productpage-policy-mtls.yaml

echo "> DestinationRule"
echo "apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productpage-destinationrule-mtls
spec:
  host: productpage
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
  subsets:
  - name: v1
    labels:
      version: v1" > $MANIFEST/productpage-destinationrule-mtls.yaml

oc create -n bookinfo -f $MANIFEST/productpage-destinationrule-mtls.yaml

echo "> VirtualService"

echo "apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage-virtualservice
spec:
  hosts:
  - productpage.bookinfo.apps.cluster-5018.5018.sandbox559.opentlc.com
  gateways:
  - bookinfo-wildcard-gateway.bookretail-istio-system.svc.cluster.local
  http:
  - match:
    - uri:
        exact: /productpage
    - uri:
        prefix: /static
    - uri:
        exact: /login
    - uri:
        exact: /logout
    - uri:
        prefix: /api/v1/products
    route:
    - destination:
        host: productpage.bookinfo.svc.cluster.local
        port:
          number: 9080" > $MANIFEST/productpage-virtualservice.yaml

oc create -n bookinfo -f $MANIFEST/productpage-virtualservice.yaml -n bookinfo


echo "> Route in $SM_CP_NS"

echo "---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
    openshift.io/host.generated: \"true\"
  labels:
    app: productpage
  name: productpage-gateway
spec:
  host: productpage.bookinfo.apps.cluster-5018.5018.sandbox559.opentlc.com
  port:
    targetPort: https
  tls:
    termination: passthrough
  to:
    kind: Service
    name: istio-ingressgateway
    weight: 100
  wildcardPolicy: None
" > $MANIFEST/productpage-route.yml

oc create -n bookinfo -f $MANIFEST/productpage-route.yml -n $SM_CP_NS


# Review
######################################################################################

echo ""
echo ">> BookInfo - Reviews"
echo "> Policy"

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: reviews-policy-mtls
spec:
  peers:
  - mtls:
      mode: STRICT
  targets:
  - name: review" > $MANIFEST/reviews-policy-mtls.yaml

oc create -n bookinfo -f $MANIFEST/reviews-policy-mtls.yaml

echo "> DestinationRule"

echo "apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews-destinationrule-mtls
spec:
  host: reviews
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
    loadBalancer:
      simple: RANDOM
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v3
    labels:
      version: v3" > $MANIFEST/reviews-destinationrule-mtls.yaml

oc create -n bookinfo -f $MANIFEST/reviews-destinationrule-mtls.yaml

echo "> VirtualService"

echo "apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews-virtualservice
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 50
    - destination:
        host: reviews
        subset: v2
      weight: 25
    - destination:
        host: reviews
        subset: v3
      weight: 25" > $MANIFEST/reviews-virtualservice.yaml

oc create -n bookinfo -f $MANIFEST/reviews-virtualservice.yaml

# Rating
############################################################################################

echo ""
echo ">> Bookinfo - Rating"
echo "> Policy"

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: ratings-policy-mtls
spec:
  peers:
  - mtls:
      mode: STRICT
  targets:
  - name: review" > $MANIFEST/ratings-policy-mtls.yaml

oc create -n bookinfo -f $MANIFEST/ratings-policy-mtls.yaml

echo "> DestinationRule"

echo "apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: ratings-destinationrule-mtls
spec:
  host: ratings
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
  subsets:
  - name: v1
    labels:
      version: v1 " > $MANIFEST/ratings-destinationrule-mtls.yaml

oc create -n bookinfo -f $MANIFEST/ratings-destinationrule-mtls.yaml

echo "> VirtualServices"

echo "apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings-virtualservice
spec:
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1 " > $MANIFEST/ratings-virtualservice.yaml

oc create -n bookinfo -f $MANIFEST/ratings-virtualservice.yaml


# Details
##############################################################################################

echo ""
echo ">> Bookinfo - Details"
echo "> Create Policy"

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: details-policy-mtls
spec:
  peers:
  - mtls:
      mode: STRICT
  targets:
  - name: review" > $MANIFEST/rdetails-policy-mtls.yaml

oc create -n bookinfo -f $MANIFEST/rdetails-policy-mtls.yaml

echo "> DestinationRule"

echo "apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: details-destinationrule-mtls
spec:
  host: details
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
  subsets:
  - name: v1
    labels:
      version: v1 " > $MANIFEST/rdetails-destinationrule-mtls.yaml

oc create -n bookinfo -f $MANIFEST/rdetails-destinationrule-mtls.yaml

echo "> VirtualService"

echo "apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: details-virtualservice
spec:
  hosts:
  - details
  http:
  - route:
    - destination:
        host: details
        subset: v1 " > $MANIFEST/rdetails-virtualservice.yaml

oc create -n bookinfo -f $MANIFEST/rdetails-virtualservice.yaml
EOF
```

```bash
chmod +x 7-istio-resources-bookinfo.sh
./7-istio-resources-bookinfo.sh
```

### Grant permission to user1 for mesh-admin

```bash
cat << EOF >> ./scripts/8-grant-permission-user1.sh
#!/bin/bash
# grant permission user1 like mesh-admin
oc adm policy add-role-to-user edit user1 -n bookretail-istio-system
oc adm policy add-role-to-user admin user1 -n bookinfo
EOF
```

```bash
chmod +x ./scripts/8-grant-permission-user1.sh
./scripts/8-grant-permission-user1.sh
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




















