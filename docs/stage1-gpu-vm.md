# Этап 1: Ansible на GPU-ВМ (self-hosted LLM API)

> **Актуальный отчёт и проверка ТЗ:** [SUBMISSION.md](SUBMISSION.md). Ниже — вспомогательные заметки по подготовке ВМ на immers.

Сценарий сдачи тестового задания: **драйверы NVIDIA, Docker, Ollama (или vLLM), автозапуск, healthcheck, свой API** на арендованной GPU-ВМ [immers.cloud](https://immers.cloud).

Control node — **ваш ПК** (`ansible-playbook` по SSH). Отдельный сервер под Ansible не нужен.

## Шаги

| # | Действие |
|---|----------|
| 1 | Создать ВМ: пресет **rtx4090-1.8.32.160**, Ubuntu **22.04** |
| 2 | Создать пользователя `ansible` на ВМ — [bootstrap-ansible-user.md](bootstrap-ansible-user.md) |
| 2b | Ключ в `certs/`, настроить `inventory/hosts.yml` |
| 3 | `ansible-galaxy collection install -r requirements.yml` |
| 4 | Проверка SSH: `ansible gpu_llm -m ping` |
| 5 | `ansible-playbook playbooks/stage1.yml --tags base,nvidia,docker,ollama` |
| 6 | `ansible-playbook playbooks/stage1.yml --tags models` |
| 7 | `ansible-playbook playbooks/stage1.yml --tags verify` |
| 8 | Ручные `curl` (см. ниже) |
| 9 | Остановить ВМ в панели immers |

Если после установки драйвера `nvidia-smi` не работает — **перезагрузите ВМ** и повторите шаги с тегом `nvidia`.

Повторный прогон без `ollama pull`: в `inventory/group_vars/gpu_llm/vars.yml` установите `ollama_pull_models: false`.

## Inventory (пример)

```yaml
# inventory/hosts.yml (файл в .gitignore)
all:
  children:
    gpu_llm:
      hosts:
        gpu01:
          ansible_host: YOUR_VM_IP
          ansible_user: ansible
          ansible_ssh_private_key_file: certs/your-private-key.pem
```

```bash
chmod 600 certs/*.pem
```

## Критерии приёмки этапа 1

- [ ] `nvidia-smi` на ВМ без ошибок
- [ ] Роль `docker`: smoke `docker run --gpus all ... nvidia-smi`
- [ ] `systemctl is-enabled ollama-compose` → enabled
- [ ] `curl http://127.0.0.1:11434/api/tags` — модель из `ollama_models` в списке
- [ ] Chat API возвращает текст ответа

## Проверка своего API на ВМ

```bash
MODEL=qwen2.5:7b

curl -s "http://127.0.0.1:11434/api/tags"
curl -s "http://127.0.0.1:11434/api/chat" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"${MODEL}\",\"messages\":[{\"role\":\"user\",\"content\":\"Привет\"}],\"stream\":false}"

curl -s "http://127.0.0.1:11434/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"${MODEL}\",\"messages\":[{\"role\":\"user\",\"content\":\"test\"}]}"
```

## vLLM (альтернатива Ollama)

В `inventory/group_vars/gpu_llm/vars.yml`: `llm_runtime: vllm`, затем полный прогон `playbooks/stage1.yml`.

Проверка: `curl -s http://127.0.0.1:8000/v1/models`

## Внешний доступ (не обязательно для сдачи)

По умолчанию API только на **127.0.0.1**. Для выхода в интернет: `enable_reverse_proxy: true` и токен (см. README).

Ориентир стоимости одного прогона: **~$1–2** при ~$0.93–1.0/ч и 1–2 ч работы ВМ.

Отчёт о проверке (DevHeader, curl, скриншоты): [verification.md](verification.md).
