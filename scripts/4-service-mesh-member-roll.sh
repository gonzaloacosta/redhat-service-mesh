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
