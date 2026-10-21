# ansible-gpu-llm-inference

Ansible-плейбук для Ubuntu + NVIDIA GPU: драйверы, Docker, NVIDIA Container Toolkit, **Ollama** (или **vLLM**) с API, автозапуском и проверкой работоспособности.

Подготовлено для PoC на [immers.cloud](https://immers.cloud) (почасовая/поминутная аренда GPU).

## Что делает playbook

| Компонент | Роль |
|-----------|------|
| Базовая ОС, UFW | `common` |
| NVIDIA driver / `nvidia-smi` | `nvidia` |
| Docker + GPU в контейнерах | `docker` |
| Ollama (по умолчанию) | `ollama` |
| vLLM (опционально) | `vllm` |
| Nginx + Bearer token | `reverse_proxy` |
| node_exporter (заготовка) | `monitoring` |

## Рекомендуемая конфигурация immers (7–8B)

- **GPU:** 1× RTX 4090 24 GB  
- **Пресет:** `rtx4090-1.8.32.160` (~[каталог 4090](https://en.immers.cloud/gpu/4090/))  
- **ОС:** Ubuntu 22.04 LTS  

Подробный бюджетный чеклист: [docs/budget-run.md](docs/budget-run.md).

## Этап 0: попробовать модель без своей GPU

Каталог [Immers Foundation Models — «можно попробовать»](https://immers.cloud/ai/model/?sort=-ICanTry): публичный API для теста клиента без аренды ВМ.  
Пример запроса: [docs/immers-public-api.md](docs/immers-public-api.md).

## Где запускать Ansible

**Control node — ваш ПК** (Linux / macOS / WSL). Отдельный сервер под Ansible не нужен.

```text
[ноутбук] --SSH--> [GPU-ВМ immers]
     ansible-playbook
```

## Быстрый старт

### 1. Зависимости на ПК

```bash
pip install ansible ansible-lint yamllint
ansible-galaxy collection install -r requirements.yml
```

### 2. Inventory

```bash
cp inventory/hosts.yml.example inventory/hosts.yml
# укажите ansible_host, ansible_user, ключ SSH
```

Переменные: `inventory/group_vars/gpu_llm.yml` (образец — `gpu_llm.yml.example`).

### 3. Запуск (бюджетно, по тегам)

```bash
ansible-playbook playbooks/site.yml --tags base,nvidia,docker,ollama
ansible-playbook playbooks/site.yml --tags models
ansible-playbook playbooks/site.yml --tags verify
```

Полный прогон:

```bash
ansible-playbook playbooks/site.yml
```

### 4. Проверка на сервере

```bash
nvidia-smi
docker ps
curl -s http://127.0.0.1:11434/api/tags
```

**Chat API (Ollama):**

```bash
curl -s http://127.0.0.1:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:7b",
    "messages": [{"role": "user", "content": "Привет"}],
    "stream": false
  }'
```

**OpenAI-compatible:**

```bash
curl -s http://127.0.0.1:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:7b",
    "messages": [{"role": "user", "content": "test"}]
  }'
```

**Python:**

```python
import requests

r = requests.post(
    "http://127.0.0.1:11434/api/chat",
    json={
        "model": "qwen2.5:7b",
        "messages": [{"role": "user", "content": "Привет"}],
        "stream": False,
    },
    timeout=120,
)
print(r.json()["message"]["content"])
```

## Переключение на vLLM

В `inventory/group_vars/gpu_llm.yml`:

```yaml
llm_runtime: vllm
```

Проверка: `curl -s http://127.0.0.1:8000/v1/models`

## Безопасность API

- По умолчанию Ollama слушает **127.0.0.1:11434** (не светит порт в интернет).
- Для внешнего доступа: `enable_reverse_proxy: true` и задайте `reverse_proxy_api_token` (лучше через Ansible Vault).
- Ограничьте SSH в `ufw_allow_ssh_from` своим IP.

## Мониторинг GPU (улучшение)

- `enable_monitoring: true` — поднимает `node_exporter` на localhost.
- Для GPU-метрик добавьте DCGM exporter или Prometheus + Grafana (см. комментарий в роли `monitoring`).

## Проверка без GPU

```bash
yamllint .
ansible-lint playbooks/site.yml
ansible-playbook playbooks/site.yml --syntax-check
```

## Структура

```text
playbooks/site.yml    # главный playbook
roles/                # common, nvidia, docker, ollama, vllm, reverse_proxy, monitoring
inventory/            # hosts + group_vars
docs/                 # бюджетный прогон, immers public API
```

## Лицензия

MIT (при необходимости укажите свою).
