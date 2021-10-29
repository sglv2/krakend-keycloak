#!/bin/bash

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

if [[ -z "${KEYCLOAK_DB_PASSWORD}" ]]; then
    KEYCLOAK_DB_PASSWORD="keycl0ak"
fi

if [[ -z "${KEYCLOAK_INGRESS_HOSTNAME}" ]]; then
    KEYCLOAK_INGRESS_HOSTNAME="keycloak.local"
fi

set -u

echo "KEYCLOAK_DB_PASSWORD=${KEYCLOAK_DB_PASSWORD}"
echo "KEYCLOAK_INGRESS_HOSTNAME=${KEYCLOAK_INGRESS_HOSTNAME}"

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update

# postgres
if [[ $(secret_exists postgres) -eq 0 ]]; then
    kubectl create secret generic postgres \
    --from-literal=postgresql-password=${KEYCLOAK_DB_PASSWORD}
fi

set -e
helm upgrade -i pg bitnami/postgresql \
    --version 10.3.18 \
    --values helm/postgres/values.yaml
set +e

## Create the wiki database

wait_for_postgres

set -e
kubectl run pg-postgresql-client --rm --tty -i --restart='Never' \
    --namespace default \
    --image docker.io/bitnami/postgresql:11.11.0-debian-10-r71 \
    --env="PGPASSWORD=${KEYCLOAK_DB_PASSWORD}" \
    --command -- psql --host pg-postgresql -U postgres -d postgres -p 5432 -c 'CREATE DATABASE keycloak'

# nginx-ingress
helm upgrade -i ni nginx-stable/nginx-ingress \
  --version 0.9.1 \
  --values helm/nginx-ingress/values.yaml

set -e