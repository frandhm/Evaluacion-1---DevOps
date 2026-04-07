# Terraform AWS — Infraestructura Inovatech

## Descripción

Infraestructura gestionada con Terraform para desplegar en **AWS** (región `us-east-1`):

- Una **VPC** (`10.0.0.0/16`) con **Internet Gateway** y **NAT Gateway** (con **Elastic IP** estática).
- **Dos subredes**: una **pública** (`10.0.1.0/24`) y una **privada** (`10.0.2.0/24`), en la misma AZ (`us-east-1a`).
- **Tablas de rutas**: tráfico saliente público vía IGW; salida desde la subred privada vía NAT.
- **Tres instancias EC2 (Ubuntu)**:
  - **Frontend** en subred pública: Nginx, build del frontend (Node.js) y proxy `/api/` hacia el backend.
  - **Backend** en subred privada (IP fija `10.0.2.20`): API Spring Boot (Java/Maven).
  - **Base de datos** en subred privada (IP fija `10.0.2.10`): MySQL con datos iniciales.
- **Security Groups** separados (frontend, backend, base de datos) con reglas entre capas.

> **Nota:** El acceso SSH está definido en los Security Groups (puerto 22). En producción conviene restringir el origen (IP/VPN).

---

## Estructura del proyecto

```
Evaluacion-1---DevOps/
├── .github/
│   └── workflows/
│       └── ci.yml                         # Pipeline CI/CD (GitHub Actions)
├── infra/
│   ├── provider.tf                        # Provider AWS y región
│   ├── vpc.tf                             # VPC, IGW, NAT, EIP, route tables
│   ├── subnet.tf                          # Subredes pública y privada
│   ├── security_groups.tf                 # SG frontend, backend, DB
│   ├── instances.tf                       # EC2 + user_data (despliegue de app)
│   └── output.tf                          # Salida (p. ej. IP pública del frontend)
├── frontend/
│   └── src/
│       ├── App.jsx                        # Componente principal, consume /api/ropas
│       ├── Card.jsx                       # Componente de tarjeta de producto
│       └── App.test.jsx                   # Tests unitarios con Vitest
├── backend/
│   └── src/
│       ├── main/java/com/ropitadeluxe/backend/
│       │   ├── controller/
│       │   │   └── RopaController.java    # Endpoint GET /api/ropas
│       │   ├── model/
│       │   │   └── Ropa.java              # Entidad JPA
│       │   └── repository/
│       │       └── RopaRepository.java    # Repositorio JPA
│       └── test/java/com/ropitadeluxe/backend/
│           └── RopaControllerTest.java    # Tests unitarios con JUnit y Mockito
└── readme.md
```

---

## Requisitos

- **Terraform CLI** ≥ 1.0
- **Cuenta AWS** con permisos para crear VPC, EC2, EIP, etc.
- **AWS CLI** (`aws configure`) o variables de entorno (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, región / perfil).
- **Par de claves EC2** en la región `us-east-1` con el nombre **`inovatech-key`** (o cambia `key_name` en `instances.tf`).

---

## Flujo de uso

1. Clona el repositorio.
2. Desde la carpeta `infra/`:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. Tras el despliegue, consulta la IP pública del frontend:

   ```bash
   terraform output
   ```
> **Nota:** El backend puede tardar alrededor de 5 minutos en estar disponible tras el `terraform apply` debido a la compilación con Maven. Si la página carga pero no muestra productos, espera unos minutos y recarga.

---

## Verificar el despliegue

1. Obtén la IP pública del frontend desde la consola de AWS: **EC2 → Instancias → inovatech-frontend → Dirección IPv4 pública**.
2. Abre en el navegador: `http://<IP-PUBLICA>`
3. Deberías ver la tienda con los productos cargados.

Para verificar la conexión frontend-backend desde el EC2 del frontend:
```bash
# Verificar que el backend responde
curl http://10.0.2.20:8080/api/ropas

# Verificar que nginx redirige correctamente
curl http://localhost/api/ropas
```

Para revisar los logs de cada instancia:
```bash
# Logs del user_data (frontend y backend)
cat /var/log/user-data.log

# Logs de la aplicación Spring Boot
cat /home/ubuntu/app.log

# Estado del servicio del backend
sudo systemctl status backend
```

---

## Tests

### Backend

Los tests del backend usan **JUnit 5** y **Mockito**, sin necesidad de base de datos activa ya que el repositorio se simula con mocks.
```bash
cd backend
mvn test
```

El test principal `RopaControllerTest` verifica que el controlador retorna correctamente la lista de productos

## Pipeline CI/CD (GitHub Actions)

El proyecto incluye un pipeline en `.github/workflows/` que se ejecuta automáticamente en cada push a `develop` o pull request:

- **frontend-build:** Instala dependencias con Node 20 y construye la aplicación con Vite.
- **backend-build:** Compila el proyecto con Java 17 y Maven omitiendo los tests de integración.

Para correr los tests localmente:
```bash
# Frontend
cd frontend
npm run test

# Backend
cd backend
mvn test
```
> **Nota:** El test `BackendApplicationTests` (generado automáticamente por Spring Boot) requiere una base de datos activa para levantar el contexto completo. Si no tienes MySQL corriendo localmente, agrégale `@Disabled` o configura una base de datos H2 en memoria en `src/test/resources/application.properties`.

---

### Frontend

Los tests del frontend usan **Vitest** y **React Testing Library**.
```bash
cd frontend
npm run test
```

---

## ¿Qué despliega este proyecto?

| Área | Contenido |
|------|-----------|
| **Red** | VPC, subredes, IGW, NAT, rutas y asociaciones. |
| **Compute** | Tres EC2 `t3.micro` con `user_data` que instala dependencias, clona el repo, construye frontend/backend y configura Nginx/MySQL/servicio systemd. |
| **Seguridad** | SGs: HTTP (80) al frontend; API (8080) solo desde el SG del frontend; MySQL (3306) solo desde el SG del backend. |

Para entornos reales conviene externalizar secretos (AWS Systems Manager Parameter Store, Secrets Manager) y parametrizar con `variables.tf` / `terraform.tfvars`.

---

## Mejores prácticas ya presentes (y mejoras posibles)

- Separación lógica por archivos (`vpc`, `subnet`, `security_groups`, `instances`).
- Subred privada para backend y base de datos; salida a Internet vía NAT.
- Tags en varios recursos (`Name`).

**Mejoras habituales:** variables en lugar de valores fijos (AMI, CIDR, IPs), módulos, backend remoto de estado (S3 + DynamoDB), restricción de SSH por IP/VPN.

---

## Cómo extender este proyecto

- Añadir **Application Load Balancer** y Auto Scaling para el frontend y/o el backend.
- Sustituir MySQL en EC2 por **Amazon RDS**.
- **CI/CD** (GitHub Actions / AWS CodePipeline) para build y despliegue.
- **Terraform workspaces** o `tfvars` por entorno (dev/staging/prod).

---

## Diagrama de arquitectura

![Diagrama de arquitectura AWS](./assets/Diagrama%20de%20Arquitectura.png)

## Aplicación (referencia)

- **Frontend:** `frontend/` — build servido por Nginx en la instancia pública.
- **Backend:** `backend/` — Spring Boot en la instancia privada; el frontend proxifica `/api/` a `http://10.0.2.20:8080`.
