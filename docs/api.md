# Серверные функции (эскиз)

## POST /analyze

Запуск анализа для загруженного файла.

Request:

```json
{ "file_id": "uuid", "force": false }
```

Response:

```json
{ "receipt_id": "uuid", "status": "processing" }
```

## GET /status?receipt_id=uuid

Response:

```json
{ "receipt_id": "uuid", "status": "ready", "error": null }
```

## Webhook/Trigger

- По загрузке в бакет — опционально инициировать анализ.
