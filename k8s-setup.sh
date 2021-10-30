#!/bin/bash
export KEYCLOAK_DOMAIN=1.2.3.4.nip.io
export KEYCLOAK_PASSWORD=keycl0ak
export KEYCLOAK_DB_PASSWORD=keycl0ak

# export STORAGE_CLASS=demo-hostpath
# kubectl apply -f demo-persistence.yaml

cat <<EOF > keycloak-values.yaml
keycloak:
  ingress:
    enabled: true
    annotations:      
      kubernetes.io/ingress.class: nginx
      kubernetes.io/tls-acme: "true"    
      ingress.kubernetes.io/affinity: cookie
    hosts:
    - ${KEYCLOAK_DOMAIN}
    path: /auth
  username: keycloak
  password: ${KEYCLOAK_PASSWORD}
  persistence:    
    deployPostgres: true
    dbVendor: postgres
    dbPassword: ${KEYCLOAK_DB_PASSWORD}
postgresql:
  persistence:
    enabled: true
    storageClass: ${STORAGE_CLASS}
  postgresPassword: ${KEYCLOAK_DB_PASSWORD}
EOF

helm upgrade \
  --install \
  --reset-values \
  --namespace default  \
  --values keycloak-values.yaml \
  --version 7.2.1 \
  keycloak codecentric/keycloak

KEYCLOAK_READY_CMD="kubectl get pod keycloak-0 -o jsonpath='{.status.containerStatuses[0].ready}'"
echo "Keycloak is initializing"
while [[ $(${KEYCLOAK_READY_CMD} | grep -c true) -lt 1 ]];do
    sleep 5
    echo "....."
done

kubectl exec -it keycloak-0 -- \
   keycloak/bin/kcadm.sh config credentials \
   --server http://localhost:8080/auth \
   --realm master \
   --user keycloak \
   --password=${KEYCLOAK_PASSWORD}
kubectl exec -it keycloak-0 -- \
   keycloak/bin/kcadm.sh update realms/master -s "sslRequired=none"
