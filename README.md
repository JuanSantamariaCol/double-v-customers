# Customers Service - Microservicio de Clientes

Microservicio de gestión de clientes para el sistema de facturación electrónica de **FactuMarket S.A.**

## Tabla de Contenidos

- [Descripción](#descripción)
- [Stack Tecnológico](#stack-tecnológico)
- [Requisitos Previos](#requisitos-previos)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Uso](#uso)
- [API Endpoints](#api-endpoints)
- [Testing](#testing)
- [Despliegue](#despliegue)

## Descripción

Este microservicio proporciona una API REST para la gestión de clientes (personas naturales y empresas) con las siguientes características:

- CRUD completo de clientes
- Validaciones robustas
- Soft delete (eliminación lógica)
- Paginación
- Serialización JSON:API
- Health check endpoint
- Arquitectura de Service Objects
- Cobertura de tests > 90%

## Stack Tecnológico

- **Ruby**: 3.2+
- **Rails**: 7.2+ (modo API)
- **Base de datos**:
  - PostgreSQL (desarrollo/testing)
  - Oracle (producción)
- **Testing**: RSpec, FactoryBot, Shoulda Matchers
- **Serialización**: jsonapi-serializer
- **Paginación**: Pagy
- **CORS**: rack-cors

## Requisitos Previos

- Ruby 3.2 o superior
- PostgreSQL 12+ (para desarrollo)
- Bundler
- Git

## Instalación

### 1. Clonar el repositorio

```bash
git clone <repository-url>
cd customers-service
```

### 2. Instalar dependencias

```bash
bundle install
```

### 3. Configurar variables de entorno

```bash
cp .env.example .env
# Editar .env con tus configuraciones locales
```

### 4. Crear y configurar la base de datos

```bash
# Crear las bases de datos
rails db:create

# Ejecutar migraciones
rails db:migrate

# (Opcional) Cargar datos de prueba
rails db:seed
```

### 5. Ejecutar el servidor

```bash
# El servicio correrá en http://localhost:3001
rails server -p 3001
```

## Configuración

### Variables de Entorno

Ver `.env.example` para todas las variables disponibles:

```bash
# Base de datos PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=

# Servidor
PORT=3001
RAILS_ENV=development
```

### Configuración de Oracle (Producción)


- Cómo montar Oracle en DigitalOcean con Docker
- Configuración paso a paso del usuario y base de datos
- Variables de entorno necesarias
- Troubleshooting y mantenimiento
- Alternativas (Oracle Cloud Free Tier)

**Resumen rápido:**

1. Descomentar las gemas de Oracle en `Gemfile`:
```ruby
gem "activerecord-oracle_enhanced-adapter", "~> 7.0"
gem "ruby-oci8"
```

2. Configurar variables de entorno (ver `.env.example`):
```bash
ORACLE_USER=customers_user
ORACLE_PASSWORD=tu-password
ORACLE_HOST=tu-droplet-ip
ORACLE_PORT=1521
ORACLE_SID=XE
```

3. Actualizar `config/database.yml` para usar Oracle en producción

4. Ejecutar migraciones: `RAILS_ENV=production rails db:migrate`

## Uso

### Health Check

Verificar que el servicio esté funcionando:

```bash
curl http://localhost:3001/api/v1/health
```

Respuesta:
```json
{
  "status": "ok",
  "service": "customers-service",
  "timestamp": "2025-01-15T10:30:00Z",
  "database": "connected",
  "version": "1.0.0"
}
```

## API Endpoints

Base URL: `http://localhost:3001/api/v1`

### Clientes

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/customers` | Listar clientes (paginado) |
| GET | `/customers/:id` | Obtener un cliente |
| POST | `/customers` | Crear un cliente |
| PATCH/PUT | `/customers/:id` | Actualizar un cliente |
| DELETE | `/customers/:id` | Eliminar un cliente (soft delete) |

### Ejemplos de Uso

#### Crear un cliente

```bash
curl -X POST http://localhost:3001/api/v1/customers \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {
      "name": "Juan Pérez",
      "person_type": "natural",
      "identification": "1234567890",
      "email": "juan@example.com",
      "phone": "3001234567",
      "address": "Calle 123 #45-67, Bogotá"
    }
  }'
```

Respuesta (201 Created):
```json
{
  "data": {
    "id": "1",
    "type": "customer",
    "attributes": {
      "name": "Juan Pérez",
      "person_type": "natural",
      "identification": "1234567890",
      "email": "juan@example.com",
      "phone": "3001234567",
      "address": "Calle 123 #45-67, Bogotá",
      "active": true,
      "created_at": "2025-01-15T10:30:00Z",
      "updated_at": "2025-01-15T10:30:00Z"
    }
  }
}
```

#### Listar clientes (con paginación)

```bash
curl "http://localhost:3001/api/v1/customers?page=1&per_page=20"
```

Respuesta (200 OK):
```json
{
  "data": [
    {
      "id": "1",
      "type": "customer",
      "attributes": {
        "name": "Juan Pérez",
        "person_type": "natural",
        "identification": "1234567890",
        "email": "juan@example.com",
        "phone": "3001234567",
        "address": "Calle 123 #45-67, Bogotá",
        "active": true,
        "created_at": "2025-01-15T10:30:00Z",
        "updated_at": "2025-01-15T10:30:00Z"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100,
    "per_page": 20
  }
}
```

#### Obtener un cliente

```bash
curl http://localhost:3001/api/v1/customers/1
```

#### Actualizar un cliente

```bash
curl -X PATCH http://localhost:3001/api/v1/customers/1 \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {
      "name": "Juan Carlos Pérez",
      "phone": "3009876543"
    }
  }'
```

#### Eliminar un cliente (soft delete)

```bash
curl -X DELETE http://localhost:3001/api/v1/customers/1
```

Respuesta: 204 No Content

### Manejo de Errores

#### Validación fallida (422)

```json
{
  "errors": [
    {
      "field": "email",
      "message": "no es válido"
    },
    {
      "field": "identification",
      "message": "ya está en uso"
    }
  ]
}
```

#### Cliente no encontrado (404)

```json
{
  "error": {
    "code": "customer_not_found",
    "message": "El cliente con ID 999 no fue encontrado"
  }
}
```

## Testing

### Ejecutar toda la suite de tests

```bash
bundle exec rspec
```

### Ejecutar tests específicos

```bash
# Tests de modelo
bundle exec rspec spec/models

# Tests de requests
bundle exec rspec spec/requests

# Test específico
bundle exec rspec spec/models/customer_spec.rb
```

### Cobertura de Tests

Para ver el reporte de cobertura:

```bash
bundle exec rspec
open coverage/index.html
```

### Estructura de Tests

```
spec/
├── factories/
│   └── customers.rb          # Factories para testing
├── models/
│   └── customer_spec.rb      # Tests del modelo
└── requests/
    └── api/
        └── v1/
            ├── customers_spec.rb  # Tests de endpoints
            └── health_spec.rb     # Tests de health check
```

## Modelo de Datos

### Customer

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | INTEGER | PK, AUTO | ID único |
| name | VARCHAR(255) | NOT NULL | Nombre completo o razón social |
| person_type | VARCHAR(20) | NOT NULL | 'natural' o 'empresa' |
| identification | VARCHAR(50) | NOT NULL, UNIQUE | NIT o Cédula |
| email | VARCHAR(255) | NOT NULL | Correo electrónico |
| phone | VARCHAR(20) | NULLABLE | Número de contacto |
| address | VARCHAR(500) | NOT NULL | Dirección completa |
| active | INTEGER | DEFAULT 1 | 1=Activo, 0=Inactivo |
| created_at | TIMESTAMP | NOT NULL | Fecha de creación |
| updated_at | TIMESTAMP | NOT NULL | Fecha de actualización |

### Validaciones

- **name**: Requerido, máximo 255 caracteres
- **person_type**: Requerido, debe ser 'natural' o 'empresa'
- **identification**: Requerido, único, máximo 50 caracteres
- **email**: Requerido, formato de email válido, máximo 255 caracteres
- **phone**: Opcional, máximo 20 caracteres
- **address**: Requerido, máximo 500 caracteres

## Arquitectura

### Estructura del Proyecto

```
app/
├── controllers/
│   └── api/
│       └── v1/
│           ├── customers_controller.rb
│           └── health_controller.rb
├── models/
│   └── customer.rb
├── serializers/
│   └── customer_serializer.rb
└── services/
    └── customers/
        ├── creator_service.rb
        └── updater_service.rb
```

### Service Objects

El proyecto implementa el patrón Service Objects para encapsular la lógica de negocio:

- `Customers::CreatorService`: Creación de clientes
- `Customers::UpdaterService`: Actualización de clientes

Cada service retorna un objeto `Result` con:
- `success?`: Indica si la operación fue exitosa
- `failure?`: Indica si la operación falló
- `customer`: El objeto customer (si fue exitoso)
- `errors`: Los errores de validación (si falló)

## Docker

El proyecto incluye un `Dockerfile` optimizado para producción que:

- Utiliza multi-stage builds para minimizar el tamaño de la imagen final
- Está basado en Alpine Linux para una imagen ligera
- Incluye las dependencias necesarias para Oracle (libaio, libnsl)
- Ejecuta la aplicación como usuario no-root para mayor seguridad
- Excluye gems de desarrollo y testing en producción

### Build de la imagen

```bash
docker build -t customers-service:latest .
```

### Ejecutar el contenedor

**Nota importante**: Este contenedor requiere una base de datos Oracle externa ya configurada.

```bash
docker run -d \
  -p 3001:3001 \
  -e RAILS_ENV=production \
  -e SECRET_KEY_BASE=your-secret-key \
  -e ORACLE_USER=your-oracle-user \
  -e ORACLE_PASSWORD=your-oracle-password \
  -e ORACLE_HOST=your-oracle-host \
  -e ORACLE_PORT=1521 \
  -e ORACLE_SID=your-oracle-sid \
  --name customers-service \
  customers-service:latest
```

### Variables de entorno requeridas

Para producción con Oracle, configura las siguientes variables (ver `.env.example`):

```bash
# Rails
SECRET_KEY_BASE=tu-secret-key-generado-con-rails-secret
RAILS_ENV=production

# Oracle Database
ORACLE_USER=customers_user
ORACLE_PASSWORD=tu-password-seguro
ORACLE_HOST=tu-droplet-ip-o-hostname
ORACLE_PORT=1521
ORACLE_SID=XE
```

**Generar SECRET_KEY_BASE:**
```bash
rails secret
```

### Ejecutar migraciones

```bash
docker run --rm \
  -e RAILS_ENV=production \
  -e ORACLE_USER=your-oracle-user \
  -e ORACLE_PASSWORD=your-oracle-password \
  -e ORACLE_HOST=your-oracle-host \
  -e ORACLE_PORT=1521 \
  -e ORACLE_SID=your-oracle-sid \
  customers-service:latest \
  rails db:migrate
```

## Despliegue

### Preparación para Producción

1. Configurar variables de entorno de producción
2. Ejecutar migraciones: `RAILS_ENV=production rails db:migrate`
3. Configurar servidor web (Puma configurado por defecto en el Dockerfile)

### Recomendaciones

- Usar un servidor de aplicaciones como Puma o Passenger
- Configurar un reverse proxy (Nginx o Apache)
- Implementar monitoreo y logging
- Configurar backups automáticos de la base de datos
- Usar variables de entorno para secretos (no commitear en git)

## Próximos Pasos

- [ ] Docker setup para containerización
- [ ] CI/CD pipeline
- [ ] Outbox pattern para eventos
- [ ] Autenticación y autorización
- [ ] Rate limiting
- [ ] Caching con Redis
- [ ] Documentación con Swagger/OpenAPI

## Contribución

1. Fork el proyecto
2. Crear una rama para tu feature (`git checkout -b feature/amazing-feature`)
3. Commit tus cambios (`git commit -m 'Add amazing feature'`)
4. Push a la rama (`git push origin feature/amazing-feature`)
5. Abrir un Pull Request

## Licencia

[MIT License](LICENSE)

## Contacto

FactuMarket S.A. - info@factumarket.com

Project Link: [https://github.com/factumarket/customers-service](https://github.com/factumarket/customers-service)
