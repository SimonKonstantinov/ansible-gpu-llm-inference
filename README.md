# ansible-gpu-llm-inference

## Этап 1 — self-hosted LLM API на GPU-ВМ

Ansible разворачивает на Ubuntu + NVIDIA GPU: **драйверы**, **Docker** (GPU в контейнерах), **Ollama** или **vLLM**, **systemd**-автозапуск и **healthcheck**. После прогона — **свой API** на `http://127.0.0.1:11434` (Ollama).

Целевая площадка: [immers.cloud](https://immers.cloud), PoC 7–8B, пресет **rtx4090-1.8.32.160**, Ubuntu 22.04.

**Полный чеклист сдачи:** [docs/stage1-gpu-vm.md](docs/stage1-gpu-vm.md)  
**Что поднято и как проверить (DevHeader, curl):** [docs/verification.md](docs/verification.md)

## Соответствие ТЗ

| Требование | Где в репозитории |
|------------|-------------------|
| Драйверы NVIDIA | роль `nvidia`, `nvidia-smi` |
| Docker + окружение GPU | роль `docker`, nvidia-container-toolkit |
| Ollama / vLLM | роли `ollama` / `vllm`, `llm_runtime` в group_vars |
| Автозапуск | `systemd` unit `ollama-compose.service` |
| Проверка работоспособности | тег `verify` в `playbooks/site.yml`, `tests/verify.yml` |
| README + пример API | [verification.md](docs/verification.md), [stage1-gpu-vm.md](docs/stage1-gpu-vm.md) |

## Архитектура

```text
[ваш ПК]  --SSH (user: ansible)-->  [GPU-ВМ immers]
                                         ├── nvidia-smi
                                         ├── docker + GPU
                                         └── Ollama :11434 (localhost)
```

Control node — только ваш компьютер; отдельная ВМ под Ansible не нужна.

## Быстрый старт

```bash
pip install ansible ansible-lint yamllint
ansible-galaxy collection install -r requirements.yml
cp inventory/hosts.yml.example inventory/hosts.yml
# IP ВМ; пользователь ansible — см. docs/bootstrap-ansible-user.md
chmod 600 certs/*.pem
ansible gpu_llm -m ping

ansible-playbook playbooks/stage1.yml --tags base,nvidia,docker,ollama
ansible-playbook playbooks/stage1.yml --tags models
ansible-playbook playbooks/stage1.yml --tags verify
```

Полный прогон: `ansible-playbook playbooks/stage1.yml`

## Inventory (пример)

```yaml
gpu01:
  ansible_host: YOUR_VM_IP
  ansible_user: ansible
  ansible_ssh_private_key_file: certs/ansible-gpu-211431-simonkonst.pem
```

Переменные: `inventory/group_vars/gpu_llm/vars.yml`, секреты — `inventory/group_vars/gpu_llm/vault.yml` ([vault-setup](docs/vault-setup.md)).

## Свой API (после Ansible)

**Chat API:**

```bash
curl -s http://127.0.0.1:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5:7b","messages":[{"role":"user","content":"Привет"}],"stream":false}'
```

**OpenAI-compatible:**

```bash
curl -s http://127.0.0.1:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5:7b","messages":[{"role":"user","content":"test"}]}'
```

Модель по умолчанию задаётся в `ollama_models` (сейчас `qwen2.5:7b`).

## vLLM

```yaml
# inventory/group_vars/gpu_llm/vars.yml
llm_runtime: vllm
```

Проверка: `curl -s http://127.0.0.1:8000/v1/models`

## Роли playbook

| Компонент | Роль |
|-----------|------|
| ОС, UFW | `common` |
| NVIDIA | `nvidia` |
| Docker + GPU | `docker` |
| Ollama | `ollama` |
| vLLM | `vllm` |
| Nginx + Bearer (опционально) | `reverse_proxy` |
| node_exporter (опционально) | `monitoring` |

На этапе 1: `enable_reverse_proxy: false`, `enable_monitoring: false`.

## Безопасность

- API слушает **127.0.0.1** — не открывайте 11434 в интернет без proxy.
- Внешний доступ: `enable_reverse_proxy: true` + Ansible Vault ([docs/vault-setup.md](docs/vault-setup.md)).
- SSH-ключи только в `certs/`, каталог в `.gitignore`.



## Проверка без GPU

```bash
ansible-playbook playbooks/stage1.yml --syntax-check
ansible-playbook tests/verify.yml --syntax-check
```

## Структура

```text
playbooks/stage1.yml   # точка входа для сдачи
playbooks/site.yml     # основной playbook
docs/stage1-gpu-vm.md  # чеклист этапа 1
roles/                 # common, nvidia, docker, ollama, ...
```

## Лицензия

MIT
