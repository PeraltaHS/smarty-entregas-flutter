# Smarty Entregas

Projeto comercial de delivery — Flutter + Dart backend + PostgreSQL.

---

## Tecnologias

- **Frontend:** Flutter (Dart)
- **Backend:** Dart com `shelf` e `shelf_router`, rodando na porta `8080`
- **Banco de dados:** PostgreSQL (gerenciado via pgAdmin)

---

## Como rodar

### Backend

```bash
cd backend
dart run bin/backend.dart
```

Crie o arquivo `backend/.env` com as credenciais do banco (veja `backend/.env.example`).

### Frontend

```bash
flutter pub get
flutter run
```

---

## Banco de Dados

- **Tecnologia:** PostgreSQL
- **Nome do banco:** `smartyentregas`
- **Gerenciador recomendado:** pgAdmin

> ⚠️ **Antes de rodar o app pela primeira vez**, restaure o banco a partir de `database/schema.sql`.

Para instruções detalhadas de export/restore via pgAdmin, veja [database/README.md](database/README.md).

---

## Segurança

As senhas são armazenadas com **PBKDF2-HMAC-SHA256** (100.000 iterações, salt aleatório por usuário). Nenhuma senha trafega ou é armazenada em texto puro.
