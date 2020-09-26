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
