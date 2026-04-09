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

Crie o arquivo `backend/.env` com as credenciais do banco (veja `backend/.env.example` se existir).

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

Para instruções detalhadas de como exportar e restaurar o banco via pgAdmin, veja [database/README.md](database/README.md).
