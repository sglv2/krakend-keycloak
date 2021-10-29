# Setup
## Kubernetes
### Setup using a script
To setup using the demo script just run
```
./k8s-setup.sh
```

The Postgres password will default to `keycl0ak` and the ingress hostname to `keycloak.local`

If you want to customize these values, set the following variables
```
KEYCLOAK_PASSWORD=s0mepwd \
KEYCLOAK_INGRESS_HOSTNAME=keycloak.example.com \
./k8s-setup.sh
```