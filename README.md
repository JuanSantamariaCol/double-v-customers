# Customers Service API

API REST simple para gestión de clientes para el sistema de facturación electrónica FactuMarket S.A.

---

## ¿Qué hace este proyecto?

Es una API para gestionar clientes (crear, editar, eliminar, listar). Cada operación genera eventos que se guardan en una tabla `outbox_messages` para garantizar que no se pierdan.

**Características principales:**
- CRUD completo de clientes
- Soft delete (no borra físicamente, solo marca como inactivo)
- Outbox Pattern (guarda eventos de forma confiable)
- 105 tests automatizados

---

## Inicio Rápido con Docker

### Requisitos
- Docker Desktop instalado y corriendo

### Pasos

**1. Clonar el proyecto**
```bash
git clone <tu-repositorio>
cd customers-service
```

**2. Construir la imagen y levantar los servicios**
```bash
docker-compose build
docker-compose up -d
```

Esto levanta 5 contenedores:
- `customers_db` - Base de datos PostgreSQL
- `customers_redis` - Redis
- `customers_app` - API Rails (puerto 3000)
- `customers_worker` - Worker para jobs
- `customers_outbox_scheduler` - Publica eventos automáticamente cada 10 segundos

**3. Verificar que funciona**
```bash
curl http://localhost:3000/api/v1/health
```

Deberías ver:
```json
{
  "status": "ok",
  "service": "customers-service",
  "database": "connected",
  "version": "1.0.0"
}
```

**¡Listo!** La API está corriendo en `http://localhost:3000`

---

## Verificación Completa del Sistema

Para verificar que todo funciona correctamente desde cero, ejecuta estos comandos en orden:

**1. Verificar que todos los servicios están corriendo:**
```bash
docker-compose ps
```
Deberías ver 5 contenedores con estado "Up" o "Up (healthy)".

**2. Ejecutar todos los tests (debe pasar 105 tests):**
```bash
docker-compose exec -e RAILS_ENV=test -e DATABASE_URL=postgresql://postgres:postgres@db:5432/customers_service_test app bundle exec rspec
```

**3. Crear un cliente de prueba:**
```bash
curl -X POST http://localhost:3000/api/v1/customers \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {
      "identification": "9876543210",
      "name": "Maria Lopez",
      "email": "maria.lopez@example.com",
      "phone": "555-9999",
      "address": "Avenida Siempre Viva 742",
      "person_type": "natural"
    }
  }'
```

**4. Verificar que el evento se publicó automáticamente (espera 15 segundos):**
```bash
sleep 15 && docker-compose exec app bin/rails outbox:stats
```

Deberías ver el evento `customer.created` como `[PUBLISHED]`.

---

## Comandos Útiles

```bash
# Ver logs de todos los servicios
docker-compose logs -f

# Ver logs solo de la API
docker-compose logs -f app

# Ver logs del scheduler (auto-publicación de eventos)
docker-compose logs -f outbox_scheduler

# Detener todos los servicios
docker-compose down

# Ver estado de contenedores
docker-compose ps

# Ejecutar tests
docker-compose exec -e RAILS_ENV=test -e DATABASE_URL=postgresql://postgres:postgres@db:5432/customers_service_test app bundle exec rspec

# Ver estadísticas de eventos Outbox
docker-compose exec app bin/rails outbox:stats

# Abrir Rails console
docker-compose exec app bin/rails console
```

---

## API Endpoints

**Base URL:** `http://localhost:3000/api/v1`

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/health` | Verifica que la API esté funcionando |
| GET | `/customers` | Lista todos los clientes activos |
| GET | `/customers/:id` | Obtiene un cliente específico |
| POST | `/customers` | Crea un nuevo cliente |
| PATCH | `/customers/:id` | Actualiza un cliente |
| DELETE | `/customers/:id` | Elimina (soft delete) un cliente |

### Ejemplos de uso

**Crear un cliente:**
```bash
curl -X POST http://localhost:3000/api/v1/customers \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {
      "name": "Juan Pérez",
      "person_type": "natural",
      "identification": "12345678",
      "email": "juan@example.com",
      "address": "Calle 123"
    }
  }'
```

**Listar clientes:**
```bash
curl http://localhost:3000/api/v1/customers
```

**Obtener un cliente:**
```bash
curl http://localhost:3000/api/v1/customers/1
```

**Actualizar un cliente:**
```bash
curl -X PATCH http://localhost:3000/api/v1/customers/1 \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {
      "name": "Juan Pérez Actualizado"
    }
  }'
```

**Eliminar un cliente (soft delete):**
```bash
curl -X DELETE http://localhost:3000/api/v1/customers/1
```

---

## Outbox Pattern

Cada vez que se crea, actualiza o elimina un cliente, se genera un evento en la tabla `outbox_messages`:

| Acción | Evento Generado |
|--------|-----------------|
| Crear cliente | `customer.created` |
| Actualizar cliente | `customer.updated` |
| Eliminar cliente (active=0) | `customer.deleted` |

**El scheduler automáticamente publica estos eventos cada 10 segundos.**

### Ver estadísticas de eventos

```bash
docker-compose exec app bin/rails outbox:stats
```

Resultado:
```
=== Outbox Messages Statistics ===
Total messages: 10
Pending: 0
Published: 10
Failed: 0

=== Recent Events (last 10) ===
  [PUBLISHED] customer.deleted - 2025-10-18 20:47:43
  [PUBLISHED] customer.updated - 2025-10-18 20:47:39
  [PUBLISHED] customer.created - 2025-10-18 20:47:30
```

---

## Testing

**Ejecutar todos los tests:**
```bash
docker-compose exec -e RAILS_ENV=test -e DATABASE_URL=postgresql://postgres:postgres@db:5432/customers_service_test app bundle exec rspec
```

**Resultado esperado:**
```
105 examples, 0 failures
Finished in 8.95 seconds
```

---

## Stack Tecnológico

- **Ruby** 3.2.2
- **Rails** 7.2.2
- **PostgreSQL** 15 Adaptable a Oracle
- **Redis** 7
- **Docker** & Docker Compose

---

## Detener y Limpiar

```bash
# Detener servicios (mantiene volúmenes/datos)
docker-compose down

# Detener y eliminar TODO (⚠️ borra la base de datos)
docker-compose down -v
```

---

## Troubleshooting

**Problema: El puerto 3000 ya está en uso**
```bash
# Ver qué proceso usa el puerto
lsof -i :3000

# Matar el proceso
kill -9 <PID>
```

**Problema: Los contenedores no inician**
```bash
# Ver logs para encontrar el error
docker-compose logs app
docker-compose logs db
```

**Problema: La base de datos no se conecta**
```bash
# Verificar que el contenedor de PostgreSQL está healthy
docker-compose ps

# Debería mostrar: customers_db   Up (healthy)
```

**Desarrollado con Ruby on Rails**
