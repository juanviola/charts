# Vortex Helm Chart - Documentación Técnica

## Información General
- **Versión del Chart**: 0.1.1
- **Versión de la Aplicación**: 1.16.0
- **Tipo**: Application
- **API Version**: v2

## Arquitectura del Chart

El Helm chart de Vortex está diseñado para desplegar una stack completa de microservicios en Kubernetes. La arquitectura está compuesta por varios componentes principales:

### Componentes Core

1. **Engine**
   - Implementado como StatefulSet
   - Servicios: Headless y ClusterIP
   - Configuración de aplicación personalizada
   - Shutdown hooks configurables
   - Escalado horizontal (HPA)

2. **Gateway**
   - Deployment estándar
   - Servicio ClusterIP
   - Configuración de HPA
   - Manejo de rutas de API

3. **Gateway WebSocket**
   - Deployment especializado para conexiones WebSocket
   - Configuración independiente de escalado
   - Servicio dedicado

4. **Portal**
   - Frontend deployment
   - Servicio ClusterIP
   - Configuración de HPA

5. **Workers**
   - Worker general y Worker Audit
   - Deployments independientes
   - Configuración de escalado específica

6. **Workspace**
   - Deployment con configuración específica
   - IngressRoute personalizado
   - Servicio dedicado

### Dependencias Externas

1. **Base de Datos**
   - MariaDB v20.5.3
   - Repositorio: charts.bitnami.com/bitnami
   - Condición de activación: mariadb.enabled

2. **Cache**
   - Redis v21.1.3
   - Repositorio: charts.bitnami.com/bitnami
   - Condición de activación: redis.enabled

3. **Búsqueda**
   - OpenSearch v3.0.0
   - Repositorio: opensearch-project.github.io/helm-charts
   - Condición de activación: opensearch.enabled

4. **Mensajería**
   - RabbitMQ v16.0.2
   - Repositorio: charts.bitnami.com/bitnami
   - Condición de activación: rabbitmq.enabled

5. **Ingress Controller**
   - Traefik v35.2.0
   - Repositorio: traefik.github.io/charts
   - Condición de activación: traefik.enabled

6. **Gestión de Secretos**
   - Vault v0.30.0
   - Repositorio: helm.releases.hashicorp.com
   - Condición de activación: vault.enabled

7. **External Secrets**
   - Version: 0.18.2
   - Repositorio: charts.external-secrets.io
   - Condición de activación: externalSecrets.enabled

## Configuración de Secretos

El chart implementa una gestión robusta de secretos:

1. **Secrets Base**
   - Generación automática de contraseñas
   - Secretos para MariaDB, Redis, RabbitMQ
   - URLs de conexión encriptadas

2. **External Secrets**
   - Integración con Vault
   - ClusterSecretStore configurado
   - Sincronización automática de secretos

## Configuración de Servicios

### Ingress y Networking
- Soporte para Ingress estándar y IngressRoutes de Traefik
- Configuración flexible de hosts y paths
- TLS configurable

### Monitoreo y Escalado
- Horizontal Pod Autoscaling (HPA) para componentes clave
- Configuración de recursos personalizable
- Métricas de servicio

### Persistencia
- Configuración de volúmenes para componentes stateful
- Soporte para diferentes clases de almacenamiento

## Configuración de Seguridad

1. **Service Account**
   - Creación automática configurable
   - Soporte para anotaciones personalizadas
   - Automount de credenciales API configurable

2. **Pod Security**
   - Contexto de seguridad configurable
   - Soporte para políticas de seguridad de pods

## Personalización

El chart permite una amplia personalización a través de values.yaml:

- Configuración de recursos por componente
- Variables de entorno personalizables
- Anotaciones y labels de pods
- Configuración de almacenamiento
- Parámetros de red y DNS

## Requisitos de Instalación

1. **Kubernetes**
   - Versión compatible con Helm v3
   - Acceso a los repositorios de charts dependientes

2. **Recursos**
   - Capacidad de almacenamiento suficiente para componentes stateful
   - Recursos de CPU y memoria según la escala deseada

3. **Networking**
   - Soporte para servicios tipo LoadBalancer (opcional)
   - Capacidad de DNS interno

## Notas de Mantenimiento

1. **Actualizaciones**
   - Seguir el proceso de actualización de Helm
   - Verificar compatibilidad de versiones de dependencias
   - Backup de datos críticos antes de actualizaciones mayores

2. **Monitoreo**
   - Revisar logs de componentes
   - Monitorear métricas de HPA
   - Verificar estado de secretos y configuraciones

## Configuración del values.yaml

### Configuraciones Principales

1. **Configuración Global**
   - `imagePullSecrets`: Credenciales para registro de imágenes
   - `nameOverride` y `fullnameOverride`: Personalización de nombres
   - `serviceAccount`: Configuración de la cuenta de servicio
   - `podAnnotations` y `podLabels`: Metadatos de pods

2. **Engine (Componente Principal)**
   - `engine.enabled`: Activación del componente
   - `engine.replicaCount`: Número de réplicas (default: 3)
   - `engine.actorsystem`: Nombre del sistema de actores
   - `engine.terminationGracePeriodSeconds`: Tiempo de gracia para terminación
   
   **Variables de Entorno Críticas**:
   - Configuración JVM:
     ```yaml
     env:
       JAVA_XMS: 512m
       JAVA_XMX: 2g
       JAVA_XSS: 1g
       JAVA_PARALLELGCTHREADS: 2
       JAVA_MAXDIRECTMEMORYSIZE: 2048m
     ```
   - Configuración de Conexiones:
     ```yaml
     env:
       V12_SLICK_URL: jdbc:mysql://...
       V12_REDISRW_HOSTNAME: redis://...
       V12_CLUSTER_PORT: 2552
     ```

3. **Componentes de Servicio**
   Cada componente sigue un patrón similar:
   ```yaml
   component:
     enabled: false
     autoscaling:
       enabled: false
   ```

## Ejemplos de Configuración

### Activación de Servicios Básicos

1. **Activar MariaDB**
```yaml
# values.yaml 
mariadb:
  enabled: true
  auth:
    database: vortex
    existingSecret: mysql  # Secret con las credenciales

# Asegurate de que el engine esté configurado con la URL correcta
engine:
  env:
    V12_SLICK_URL: "jdbc:mysql://vortex-mariadb:3306/vortex?useSSL=false"
```