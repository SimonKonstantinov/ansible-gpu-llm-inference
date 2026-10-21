# Публичный API Immers Foundation Models (шаблон)

Параметры берите из карточки модели в [каталоге](https://immers.cloud/ai/model/?sort=-ICanTry).

```bash
export IMMERS_API_BASE="https://YOUR_ENDPOINT_FROM_DASHBOARD/v1"
export IMMERS_API_KEY="YOUR_API_KEY"

curl -s "${IMMERS_API_BASE}/chat/completions" \
  -H "Authorization: Bearer ${IMMERS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL_ID_FROM_CATALOG",
    "messages": [{"role": "user", "content": "Привет! Ответь одним предложением."}],
    "max_tokens": 128
  }'
```

Публичный эндпоинт **не заменяет** self-hosted стек из Ansible — это нулевой шаг для проверки клиента без аренды GPU.
