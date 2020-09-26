#!/bin/bash

# Apply Istio Resources for bookinfo with mTLS STRICT Policy

export SM_CP_NS=bookretail-istio-system
export MANIFEST=$HOME/lab/manifest/
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


