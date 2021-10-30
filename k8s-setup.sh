#!/bin/bash
export KEYCLOAK_PASSWORD=keycl0ak
export KEYCLOAK_DB_USER=postgres
export KEYCLOAK_DB_PASSWORD=keycl0ak

# export STORAGE_CLASS=demo-hostpath
# kubectl apply -f demo-persistence.yaml

secret_exists() {
    kubectl get secrets --field-selector=metadata.name=$1 --no-headers 2>/dev/null | wc -l
}

wait_for_postgres() {
    PG_READY_CMD="kubectl get pod pg-postgresql-0 -o jsonpath='{.status.containerStatuses[0].ready}'"
    echo "Postgres is initializing"
    while [[ $(${PG_READY_CMD} | grep -c true) -lt 1 ]];do
        sleep 5
        echo "....."
    done
}

wait_for_keycloak() {
   KEYCLOAK_READY_CMD="kubectl get pod keycloak-0 -o jsonpath='{.status.containerStatuses[0].ready}'"
   echo "Keycloak is initializing"
   while [[ $(${KEYCLOAK_READY_CMD} | grep -c true) -lt 1 ]];do
      sleep 5
      echo "....."
   done
}

if [[ $(secret_exists postgres) -eq 0 ]]; then
    kubectl create secret generic postgres \
    --from-literal=postgresql-user=${KEYCLOAK_DB_USER}\
    --from-literal=postgresql-password=${KEYCLOAK_DB_PASSWORD}
fi

helm upgrade -i pg bitnami/postgresql \
    --version 10.3.18 \
    --values helm/postgres/values.yaml

wait_for_postgres

kubectl run pg-postgresql-client --rm --tty -i --restart='Never' \
    --namespace default \
    --image docker.io/bitnami/postgresql:11.11.0-debian-10-r71 \
    --env="PGPASSWORD=${KEYCLOAK_DB_PASSWORD}" \
    --command -- psql --host pg-postgresql -U postgres -d postgres -p 5432 -c 'CREATE DATABASE keycloak'


helm upgrade -i \
  --reset-values \
  --namespace default  \
  --values helm/keycloak/values.yaml \
  --version 7.2.1 \
  keycloak codecentric/keycloak

wait_for_keycloak

export ORIGINAL_DIR=$(pwd)
pushd /tmp/
if [[ ! -d krakend-helm ]];then
  git clone https://github.com/sglv2/krakend-helm.git
fi

helm upgrade -i kd krakend-helm -f ${ORIGINAL_DIR}/helm/krakend-helm/values.yaml