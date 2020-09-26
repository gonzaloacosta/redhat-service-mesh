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
