#!/bin/bash
# grant permission user1 like mesh-admin
oc adm policy add-role-to-user edit user1 -n bookretail-istio-system
oc adm policy add-role-to-user admin user1 -n bookinfo
