# SiPupuk — Sistem Distribusi Pupuk Subsidi

Sistem informasi berbasis cloud untuk memantau distribusi pupuk subsidi dari distributor hingga kelompok tani.

## Struktur Project

```
pupuk-subsidi/
├── auth-service/     Node.js - Autentikasi & JWT
├── core-api/         Node.js - Business logic utama
├── frontend/         HTML + Tailwind - Web App Dinas
├── mobile/           Flutter - App Ketua Kelompok Tani
└── docs/             Dokumentasi & SQL script
```

## Tech Stack

| Layer | Teknologi |
|---|---|
| Backend | Node.js + Express |
| Frontend Web | HTML + Tailwind CSS |
| Mobile | Flutter |
| Database SQL | Cloud SQL (MySQL 8.0) |
| Database NoSQL | Firestore |
| File Storage | Cloud Storage |
| Deploy | Cloud Run |
| Container | Cloud Build + Artifact Registry |

## Quick Start

### 1. Setup GCP
```bash
# Aktifkan API
gcloud services enable run.googleapis.com sqladmin.googleapis.com \
  cloudbuild.googleapis.com artifactregistry.googleapis.com \
  storage.googleapis.com firestore.googleapis.com

# Set project
gcloud config set project YOUR_PROJECT_ID
gcloud config set run/region asia-southeast2
```

### 2. Setup Cloud SQL
```bash
gcloud sql instances create pupuk-db \
  --database-version=MYSQL_8_0 \
  --tier=db-f1-micro \
  --region=asia-southeast2 \
  --root-password=YOUR_ROOT_PASSWORD

gcloud sql databases create pupuk_subsidi --instance=pupuk-db
gcloud sql users create pupuk_user --instance=pupuk-db --password=YOUR_DB_PASSWORD
```

Lalu jalankan `docs/init-database.sql` di Cloud SQL Studio.

### 3. Setup Firestore
```bash
gcloud firestore databases create --location=asia-southeast2
```

### 4. Setup Cloud Storage
```bash
gcloud storage buckets create gs://pupuk-subsidi-bukti --location=asia-southeast2
```

### 5. Setup Artifact Registry
```bash
gcloud artifacts repositories create pupuk-repo \
  --repository-format=docker --location=asia-southeast2
```

### 6. Deploy Auth Service
```bash
# Copy .env.example ke .env dan isi semua value
cp auth-service/.env.example auth-service/.env

# Build & Deploy
gcloud builds submit ./auth-service \
  --tag asia-southeast2-docker.pkg.dev/PROJECT_ID/pupuk-repo/auth-service:latest

gcloud run deploy auth-service \
  --image asia-southeast2-docker.pkg.dev/PROJECT_ID/pupuk-repo/auth-service:latest \
  --region asia-southeast2 --allow-unauthenticated \
  --set-env-vars="DB_HOST=/cloudsql/PROJECT_ID:asia-southeast2:pupuk-db,DB_NAME=pupuk_subsidi,DB_USER=pupuk_user,DB_PASS=YOUR_PASS,JWT_SECRET=YOUR_SECRET" \
  --add-cloudsql-instances=PROJECT_ID:asia-southeast2:pupuk-db
```

### 7. Deploy Core API
```bash
gcloud builds submit ./core-api \
  --tag asia-southeast2-docker.pkg.dev/PROJECT_ID/pupuk-repo/core-api:latest

gcloud run deploy core-api \
  --image asia-southeast2-docker.pkg.dev/PROJECT_ID/pupuk-repo/core-api:latest \
  --region asia-southeast2 --allow-unauthenticated \
  --set-env-vars="DB_HOST=/cloudsql/PROJECT_ID:asia-southeast2:pupuk-db,DB_NAME=pupuk_subsidi,DB_USER=pupuk_user,DB_PASS=YOUR_PASS,JWT_SECRET=YOUR_SECRET,GCS_BUCKET=pupuk-subsidi-bukti,PROJECT_ID=YOUR_PROJECT_ID" \
  --add-cloudsql-instances=PROJECT_ID:asia-southeast2:pupuk-db
```

### 8. Deploy Frontend
```bash
# Update URL di frontend/public/assets/js/api.js terlebih dahulu

gcloud builds submit ./frontend \
  --tag asia-southeast2-docker.pkg.dev/PROJECT_ID/pupuk-repo/frontend:latest

gcloud run deploy frontend \
  --image asia-southeast2-docker.pkg.dev/PROJECT_ID/pupuk-repo/frontend:latest \
  --region asia-southeast2 --allow-unauthenticated
```

### 9. Flutter App
```bash
cd mobile
# Update URL di lib/config/api_config.dart
flutter pub get
flutter run   # untuk development
flutter build apk --release   # untuk APK
```

## Default Login (setelah seed data)

| Role | Email | Password |
|---|---|---|
| Dinas | dinas@sipupuk.id | password123 |
| Distributor | distributor@sipupuk.id | password123 |
| Ketua Tani | tani@sipupuk.id | password123 |

> **Catatan:** Hash di init-database.sql perlu di-generate ulang. Gunakan API register atau generate hash dengan: `node -e "const b=require('bcrypt');b.hash('password123',12).then(h=>console.log(h))"`

## API Endpoints

| # | Method | Path | Role |
|---|---|---|---|
| 1 | POST | /auth/register | - |
| 2 | POST | /auth/login | - |
| 3 | GET | /auth/me | all |
| 4 | PUT | /auth/change-password | all |
| 5 | GET | /wilayah | all |
| 6 | POST | /kuota | dinas |
| 7 | GET | /kuota | dinas |
| 8 | PUT | /kuota/:id | dinas |
| 9 | GET | /distributor | dinas |
| 10 | POST | /distributor | dinas |
| 11 | GET | /kelompok-tani | dinas, distributor |
| 12 | POST | /kelompok-tani | dinas |
| 13 | POST | /alokasi | dinas |
| 14 | GET | /alokasi | all |
| 15 | POST | /distribusi | distributor |
| 16 | GET | /distribusi | all |
| 17 | PUT | /distribusi/:id/status | distributor, dinas |
| 18 | POST | /penerimaan | ketua_tani |
| 19 | GET | /penerimaan | all |
| 20 | PUT | /penerimaan/:id/verifikasi | dinas |
| 21 | POST | /laporan/kelangkaan | ketua_tani |
| 22 | GET | /laporan/kelangkaan | dinas |
| 23 | GET | /laporan/distribusi | dinas |
| 24 | GET | /notifikasi | all |

## Tim Pengembang

Sistem Distribusi Pupuk Subsidi — Project Akhir Cloud Computing
