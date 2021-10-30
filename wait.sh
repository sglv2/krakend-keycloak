#!/bin/bash

wait_for_postgres() {
    PG_READY_CMD="kubectl get pod pg-postgresql-0 -o jsonpath='{.status.containerStatuses[0].ready}'"
    echo "Postgres is initializing"
    while [[ $(${PG_READY_CMD} | grep -c true) -lt 1 ]];do
        sleep 5
        echo "....."
    done
}