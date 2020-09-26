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
