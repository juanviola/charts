# Vortex Helm Chart


## Local run

#### Create secret for Azure credentials

```
kubectl create secret docker-registry acr-secret \
--docker-server=<host>.azurecr.io \
--docker-username=<user> \
--docker-password=<service_principal_password> \
--docker-email=your-email@example.com # you can use a generic email address too
```

## Configuration parameters