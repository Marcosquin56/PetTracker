# PetTracker API

Backend propio (NestJS + PostgreSQL/PostGIS) que reemplaza a Firestore,
Firebase Storage y Firebase Auth. Firebase Cloud Messaging se mantiene, pero
solo como transporte de push (el backend llama a `firebase-admin`; el móvil
solo recibe).

## Requisitos

- Node.js 20+ (instalado en este entorno vía `nvm`)
- Docker + Docker Compose, para Postgres/PostGIS y MinIO:
  ```
  sudo apt-get install -y docker.io docker-compose-plugin
  sudo usermod -aG docker "$USER"   # cierra sesión/vuelve a entrar después
  ```

## Setup

```bash
cd backend
npm install
cp .env.example .env   # y editar los secrets de JWT

docker compose up -d
npx prisma migrate dev --name init
npx prisma db execute --file prisma/sql/create_indexes.sql --schema prisma/schema.prisma

npm run start:dev
```

La API queda en `http://localhost:3000`. MinIO (consola web) en
`http://localhost:9001` (user/pass en `docker-compose.yml`) — hay que crear
el bucket `pettracker-photos` ahí manualmente la primera vez (o vía `mc`/AWS
CLI apuntando al endpoint de MinIO).

## Push (FCM)

1. Firebase Console → un proyecto nuevo o existente → Project Settings →
   Service Accounts → "Generate new private key".
2. Guardar el JSON descargado como `backend/firebase-service-account.json`
   (ya está en `.gitignore`) y apuntar `FIREBASE_SERVICE_ACCOUNT_PATH` en
   `.env` a esa ruta.

## Endpoints principales

| Método | Ruta                     | Auth | Descripción                                  |
|--------|--------------------------|------|-----------------------------------------------|
| POST   | `/auth/register`         | No   | Crea cuenta, devuelve access+refresh token    |
| POST   | `/auth/login`             | No   | Devuelve access+refresh token                 |
| POST   | `/auth/refresh`           | No   | Rota el refresh token                         |
| GET    | `/users/me`               | Sí   | Perfil del usuario autenticado                |
| PATCH  | `/users/me`               | Sí   | Actualiza perfil / última ubicación conocida  |
| POST   | `/users/me/fcm-tokens`    | Sí   | Registra un token FCM del dispositivo         |
| GET    | `/reports`                | No   | Feed reciente (sin filtro de ubicación)       |
| GET    | `/reports/nearby?lat&lng&radiusKm` | No | Reportes cercanos, ordenados por distancia |
| POST   | `/reports`                | Sí   | Crea un reporte (dispara push a usuarios cercanos) |
| PATCH  | `/reports/:id`            | Sí   | Edita un reporte propio                       |
| POST   | `/reports/:id/photos`     | Sí   | Sube una foto (`multipart/form-data`, campo `file`) |

## Verificación sin Docker

`npm run build` compila con TypeScript sin necesitar Postgres/MinIO
corriendo. Levantar y probar los endpoints reales sí requiere `docker compose
up`.
