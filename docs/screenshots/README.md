
# Скриншоты для отчёта

Положите PNG в эту папку. В отчёте они подключаются из [SUBMISSION.md](../SUBMISSION.md).

**Не публикуйте** токены Bearer, пароли Grafana/nginx и содержимое `vault.yml` — замажьте на скринах.

Имена файлов — **ровно** как в таблице (одно расширение `.png`). Если сохраняете как `02-nvidia-smi.png`, не добавляйте второй `.png` — получится `02-nvidia-smi.png.png`, и картинки в [SUBMISSION.md](../SUBMISSION.md) не найдутся.

Файл должен быть **настоящим PNG**, а не JPEG с переименованным расширением (иначе GitHub/raw может отдавать 404). Проверка: `file docs/screenshots/05-grafana-ollama.png` → `PNG image data`.

| Файл | Что снять |
|------|-----------|
| [01-verify-recap.png](01-verify-recap.png) | Терминал: `ansible-playbook ... --tags verify`, PLAY RECAP `failed=0` |
| [02-nvidia-smi.png](02-nvidia-smi.png) | SSH на ВМ: вывод `nvidia-smi` |
| [03-api-tags.png](03-api-tags.png) | Браузер или curl: `http://YOUR_VM_IP:8080/api/tags` + JSON с `qwen2.5:7b` |
| [04-grafana-gpu.png](04-grafana-gpu.png) | Grafana :8081 → **GPU → GPU DCGM** |
| [05-grafana-ollama.png](05-grafana-ollama.png) | Grafana → **LLM → Ollama LLM Inference** (`ollama_up`, модель в VRAM) |
| [06-open-webui-chat.png](06-open-webui-chat.png) | Open WebUI :8082 — чат с `qwen2.5:7b` |
| [07-grafana-nginx.png](07-grafana-nginx.png) | Grafana → **Infrastructure → nginx** (опционально) |

После загрузки файлов картинки появятся в [SUBMISSION.md](../SUBMISSION.md) автоматически (относительные ссылки).
