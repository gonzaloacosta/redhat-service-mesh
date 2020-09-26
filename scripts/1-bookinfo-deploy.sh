#!/bin/bash

# Deploy BookInfo App

echo "Create namespaces.."
oc new-project bookinfo

echo "Apply templates with deployments..."
oc apply -f https://raw.githubusercontent.com/istio/istio/1.4.0/samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo

echo "Expose application.."
oc expose service productpage
echo -en "\n$(oc get route productpage --template '{{ .spec.host }}')\n"

sleep 30

echo "Pods status..."
oc get pods -n bookinfo
