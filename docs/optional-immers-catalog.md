# Опционально: каталог Immers Foundation Models

**Не входит в сдачу этапа 1.** Используйте только если хотите попробовать модель через публичный эндпоинт immers без своей GPU-ВМ.

- [Каталог «можно попробовать»](https://immers.cloud/ai/model/?sort=-ICanTry)
- URL и API-ключ — в личном кабинете immers

```bash
export IMMERS_API_BASE="https://YOUR_ENDPOINT_FROM_DASHBOARD/v1"
export IMMERS_API_KEY="YOUR_API_KEY"

curl -s "${IMMERS_API_BASE}/chat/completions" \
  -H "Authorization: Bearer ${IMMERS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL_ID_FROM_CATALOG",
    "messages": [{"role": "user", "content": "Привет"}],
    "max_tokens": 128
  }'
```

Для задания требуется **self-hosted API** после Ansible — см. [stage1-gpu-vm.md](stage1-gpu-vm.md).
