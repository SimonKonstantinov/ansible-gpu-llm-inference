# ansible-gpu-llm-inference

Ansible-плейбук разворачивает на **GPU-ВМ** (Ubuntu + NVIDIA) стек: **Ollama** с моделью **qwen2.5:7b**, защищённый **API**, **Open WebUI** и **мониторинг** (Prometheus + Grafana).

**Полный отчёт и чеклист для проверяющего:** [docs/SUBMISSION.md](docs/SUBMISSION.md)  
**Скриншоты:** [docs/screenshots/](docs/screenshots/) · [01 verify (raw)](https://raw.githubusercontent.com/SimonKonstantinov/ansible-gpu-llm-inference/refs/heads/main/docs/screenshots/01-verify-recap.png)

<details>
<summary>Превью (raw GitHub)</summary>

| Verify | API tags |
|--------|----------|
| ![01](https://raw.githubusercontent.com/SimonKonstantinov/ansible-gpu-llm-inference/refs/heads/main/docs/screenshots/01-verify-recap.png) | ![03](https://raw.githubusercontent.com/SimonKonstantinov/ansible-gpu-llm-inference/refs/heads/main/docs/screenshots/03-api-tags.png) |

</details>

---

## Соответствие тестовому заданию

| Требование | Доказательство |
|------------|----------------|
| Ubuntu + NVIDIA | `nvidia-smi`, роль `nvidia` |
| Docker + GPU в контейнерах | роль `docker` |
| LLM (Ollama) | `qwen2.5:7b`, API `/api/tags` |
| Автозапуск | `ollama-compose.service` |
| Healthcheck | `--tags verify` → `failed=0` |
| README + пример API | ниже + [SUBMISSION.md](docs/SUBMISSION.md) |
| Защита API (доп.) | nginx **:8080** + Bearer (Vault) |
| Мониторинг GPU/сервера (доп.) | Grafana **:8081** |
| Веб-чат (доп.) | Open WebUI **:8082** |

---

## Быстрая проверка (для проверяющего)

```bash
cd ~/ansible-gpu-llm-inference
ansible-galaxy collection install -r requirements.yml
# inventory/hosts.yml, vault — см. docs/vault-setup.md

ansible-playbook playbooks/stage1.yml --vault-password-file .vault_pass
ansible-playbook playbooks/stage1.yml --tags verify --vault-password-file .vault_pass
```

Пошаговый чеклист со скриншотами: [docs/SUBMISSION.md](docs/SUBMISSION.md) (раздел «Проверка тестового задания»).

---

## Доступ

| Порт | Сервис | Аутентификация |
|------|--------|----------------|
| **8080** | Ollama API | `Authorization: Bearer <токен из Vault>` |
| **8081** | Grafana | nginx `monitor` → Grafana `admin` (Vault) |
| **8082** | Open WebUI | учётная запись в приложении |

Подробно: [docs/access-credentials.md](docs/access-credentials.md).

---

## Пример API

```bash
curl -s "http://YOUR_VM_IP:8080/api/tags" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Ожидается JSON с моделью `qwen2.5:7b`. Дополнительные примеры — в [SUBMISSION.md](docs/SUBMISSION.md).

---

## Структура репозитория

```text
playbooks/stage1.yml          # точка входа
roles/                      # common, nvidia, docker, ollama, open_webui, reverse_proxy, monitoring
inventory/group_vars/gpu_llm/
docs/SUBMISSION.md          # отчёт для сдачи
docs/screenshots/           # иллюстрации к отчёту
```

---

## Приложения

- [vault-setup.md](docs/vault-setup.md) — Ansible Vault  
- [access-credentials.md](docs/access-credentials.md) — пароли по сервисам  
- [monitoring.md](docs/monitoring.md) — дашборды Grafana  
- [open-webui.md](docs/open-webui.md) — веб-чат  

## Лицензия

MIT
