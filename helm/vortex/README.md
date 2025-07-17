# Vortex Helm Chart

## Installation process

#### Vault

1. define an namespace var `vortex`

```bash
export NS=vortex
```

2. Init Vault
```bash
kubectl get pods -n ${NS}
kubectl exec vortex-vault-0 -n ${NS} -- vault operator init
```

This will output your vault `Unseal Keys` and the Master Root Token, save all this information in a safe place.

3. Unseal it

Execute the following command, it will ask you to complete with the `Unseal Keys` secuentally. You will need to repeat this step 3 times and use a different `Unseal Key` any time.

```bash
kubectl exec -it vortex-vault-0 -n ${NS} -- vault operator unseal
```

4. Check your `Vault` pod should be on running Status

```bash
kubectl get pods -n ${NS}
```

#### External Secrets

Adding secrets to Vault

1. create a secret `vault-token` with the root token inside

```bash
cat << EOF > secret.tmp
token=$(echo "my-secret" | base64)
EOF

kubectl create secret generic vault-token --from-env-file=secret.tmp
```


2. Create a json file `secrets.json` and put all your secrets there 

```json
{
  "data": {
    "REDIS_PASSWORD": "MglSlVOg4Z_0",
    "MYSQL_USER": "app_user",
    "MYSQL_PASS": "MglSlVOg4Z_1",
    "RABBIT_USER": "user",
    "RABBIT_PASS": "MglSlVOg4Z_2",
    "ARTIFACT_USER": "deploy",
    "ARTIFACT_PASS": "4YrZewCssecDWKFA/2thFIPWo5Tfjsjt4nKz2kYGBL4A+ACRA6O1mo",
    "ARTIFACT_SERVER": "vortexio.azurecr.io",
    "config": {
      "timeout": 3000,
      "enabled": true,
      "features": ["featureA", "featureB"]
    }
  }
}
```

## Configuration parameters

#### List of components

| Name    | description |
| -------- | ------- |
| Vatul  | Centralized Secret Storage   |
| External Secrets | Automates the process of syncing secrets from your chosen external secret store into your Kubernetes cluster as standard Secret objects |
|



## Local run

#### Create secret for Azure credentials

```
kubectl create secret docker-registry acr-secret \
--docker-server=<host>.azurecr.io \
--docker-username=<user> \
--docker-password=<service_principal_password> \
--docker-email=your-email@example.com # you can use a generic email address too
```