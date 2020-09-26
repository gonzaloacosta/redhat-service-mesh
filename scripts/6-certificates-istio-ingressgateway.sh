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
commonName=.apps.cluster-5018.5018.sandbox559.opentlc.com

[req_ext]
subjectAltName   = @alt_names

[alt_names]
DNS.1  = .apps.cluster-5018.5018.sandbox559.opentlc.com
DNS.2  = *..apps.cluster-5018.5018.sandbox559.opentlc.com
" > cert.cfg

openssl req -x509 -config cert.cfg -extensions req_ext -nodes -days 730 -newkey rsa:2048 -sha256 -keyout tls.key -out tls.crt

echo "Create secrets for istio-ingressgateway..."
oc create secret tls istio-ingressgateway-certs --cert tls.crt --key tls.key -n bookretail-istio-system

echo ""
echo "Patch deployment istio-ingressgateway.."
oc patch deployment istio-ingressgateway -p '{"spec":{"template":{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt": "'2020-09-25T21:13:20+0000'"}}}}}' -n bookretail-istio-system
