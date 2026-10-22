# Open WebUI — чат с моделью

Веб-интерфейс к Ollama. Снаружи: **`http://YOUR_VM_IP:8082`** (вход только в приложении, без nginx basic auth).

Отчёт: [SUBMISSION.md](SUBMISSION.md) · Логины по портам: [access-credentials.md](access-credentials.md)

## Как проверить

1. Откройте `http://YOUR_VM_IP:8082`.
2. Зарегистрируйтесь или войдите в Open WebUI.
3. Выберите модель **qwen2.5:7b** и отправьте сообщение.

Скрин для отчёта: [screenshots/06-open-webui-chat.png](screenshots/06-open-webui-chat.png).

## Включение в playbook

```yaml
# inventory/group_vars/gpu_llm/vars.yml
enable_open_webui: true
llm_runtime: ollama
```

Развёртывание входит в полный `ansible-playbook playbooks/stage1.yml`.

## Если нет моделей в списке

Open WebUI обращается к Ollama на ВМ (`11434`). Убедитесь, что контейнер `ollama` запущен и модель скачана:

```bash
curl -s http://127.0.0.1:11434/api/tags
```
