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
Evaluacion-1-DevOps/
├── infra/
│   ├── provider.tf          # Provider AWS y región
│   ├── vpc.tf               # VPC, IGW, NAT, EIP, route tables
│   ├── subnet.tf            # Subredes pública y privada
│   ├── security_groups.tf   # SG frontend, backend, DB
│   ├── instances.tf         # EC2 + user_data (despliegue de app)
│   └── output.tf          # Salida (p. ej. IP pública del frontend)
├── frontend/                # Aplicación React/Vite
├── backend/                 # API Spring Boot
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

![Diagrama de arquitectura AWS](https://drive.google.com/uc?export=view&id=1H52j5OO8psFqt-cEjZezKyiKbpAmu9CB)

[Abrir diagrama en Google Drive](https://drive.google.com/file/d/1H52j5OO8psFqt-cEjZezKyiKbpAmu9CB/view?usp=sharing)

*Si la imagen no aparece en GitHub (Drive a veces bloquea la vista incrustada), usa el enlace anterior.*

## Aplicación (referencia)

- **Frontend:** `frontend/` — build servido por Nginx en la instancia pública.
- **Backend:** `backend/` — Spring Boot en la instancia privada; el frontend proxifica `/api/` a `http://10.0.2.20:8080`.
