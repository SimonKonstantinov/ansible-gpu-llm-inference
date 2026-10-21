# ansible-gpu-llm-inference

Ansible-плейбук для **GPU-ВМ** (Ubuntu + NVIDIA): драйверы, Docker, **Ollama** / vLLM, автозапуск, healthcheck и **свой LLM API**.

Целевая площадка: [immers.cloud](https://immers.cloud), PoC 7–8B (пресет **rtx4090-1.8.32.160**, Ubuntu 22.04).

Control node — **ваш ПК** (`ansible-playbook` по SSH). Отдельный сервер под Ansible не нужен.

## Соответствие ТЗ

| Требование | Реализация |
|------------|------------|
| Драйверы NVIDIA | роль `nvidia`, `nvidia-smi` |
| Docker + GPU | роль `docker`, nvidia-container-toolkit |
| Ollama / vLLM | роли `ollama` / `vllm` |
| Автозапуск | `systemd`: `ollama-compose.service` |
| Healthcheck | тег `verify`, `tests/verify.yml` |
| README + пример API | этот файл, [docs/verification.md](docs/verification.md) |

## Архитектура

```text
[ПК] --SSH--> [GPU-ВМ immers]
                 ├── Ollama 127.0.0.1:11434
                 └── nginx :8080 + Bearer (внешняя проверка)
```

## Быстрый старт

```bash
cd ~/ansible-gpu-llm-inference
pip install ansible   # или: sudo apt install ansible
ansible-galaxy collection install -r requirements.yml

cp inventory/hosts.yml.example inventory/hosts.yml
# IP ВМ, user ansible, ключ certs/*.pem — см. docs/bootstrap-ansible-user.md
chmod 600 certs/*.pem

ansible gpu_llm -m ping

ansible-playbook playbooks/stage1.yml --tags base,nvidia,docker,ollama
ansible-playbook playbooks/stage1.yml --tags models
ansible-playbook playbooks/stage1.yml --tags verify

# внешний API (nginx + токен из Vault):
ansible-playbook playbooks/stage1.yml --tags proxy,base --vault-password-file .vault_pass
```

Полный прогон: `ansible-playbook playbooks/stage1.yml --vault-password-file .vault_pass`

Детальный чеклист: [docs/stage1-gpu-vm.md](docs/stage1-gpu-vm.md)

## Inventory

```yaml
# inventory/hosts.yml (в .gitignore)
gpu01:
  ansible_host: YOUR_VM_IP
  ansible_user: ansible
  ansible_ssh_private_key_file: certs/ansible-gpu-211431-simonkonst.pem
```

SSH с ключом immers:

```bash
ssh -i certs/ansible-gpu-211431-simonkonst.pem -o IdentitiesOnly=yes ansible@YOUR_VM_IP
```

Переменные: `inventory/group_vars/gpu_llm/vars.yml`  
Секреты (токен API): `inventory/group_vars/gpu_llm/vault.yml` — [docs/vault-setup.md](docs/vault-setup.md)

---

## Внешняя проверка API (с интернета)

Ollama на ВМ слушает только **127.0.0.1:11434**. Снаружи API доступен через **nginx на порту 8080** с заголовком **`Authorization: Bearer <токен>`**.

### 1. Токен (Ansible Vault)

```bash
ansible-vault view inventory/group_vars/gpu_llm/vault.yml --vault-password-file .vault_pass
```

Скопируйте значение `vault_reverse_proxy_api_token`.

### 2. Браузер + расширение DevHeader

1. Установите **DevHeader** (или аналог для произвольных заголовков).
2. Добавьте заголовок:
   - **Name:** `Authorization`
   - **Value:** `Bearer ВАШ_ТОКЕН`
3. Включите правило для вкладки.
4. Откройте:

   ```text
   http://YOUR_VM_IP:8080/api/tags
   ```

**Успех:** JSON со моделью `qwen2.5:7b`.

**Chat (POST)** — в **F12 → Console**:

```javascript
const token = "ВАШ_ТОКЕН";
const ip = "YOUR_VM_IP";
fetch(`http://${ip}:8080/api/chat`, {
  method: "POST",
  headers: {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    model: "qwen2.5:7b",
    messages: [{ role: "user", content: "Привет" }],
    stream: false,
  }),
}).then((r) => r.json()).then(console.log);
```

### 3. curl с ПК

```bash
TOKEN=$(ansible-vault view inventory/group_vars/gpu_llm/vault.yml --vault-password-file .vault_pass \
  | awk -F'"' '/vault_reverse_proxy_api_token/{print $2}')

curl -s "http://YOUR_VM_IP:8080/api/tags" -H "Authorization: Bearer ${TOKEN}"

curl -s "http://YOUR_VM_IP:8080/api/chat" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5:7b","messages":[{"role":"user","content":"Привет"}],"stream":false}'
```

### 4. SSH-туннель (без токена, только для отладки)

```bash
ssh -i certs/ansible-gpu-211431-simonkonst.pem -L 11434:127.0.0.1:11434 ansible@YOUR_VM_IP
```

В браузере: `http://127.0.0.1:11434/api/tags` (nginx не используется).

Полная инструкция со скриншотами для отчёта: **[docs/verification.md](docs/verification.md)**

---

## API на самой ВМ (после SSH)

```bash
curl -s http://127.0.0.1:11434/api/tags

curl -s http://127.0.0.1:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5:7b","messages":[{"role":"user","content":"Привет"}],"stream":false}'

curl -s http://127.0.0.1:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5:7b","messages":[{"role":"user","content":"test"}]}'
```

## vLLM (опционально)

В `inventory/group_vars/gpu_llm/vars.yml`: `llm_runtime: vllm`  
Проверка: `curl -s http://127.0.0.1:8000/v1/models`

## Роли

| Роль | Назначение |
|------|------------|
| `common` | пакеты, UFW |
| `nvidia` | драйвер / `nvidia-smi` |
| `docker` | Docker + GPU в контейнерах |
| `ollama` | Ollama + systemd |
| `vllm` | альтернативный runtime |
| `reverse_proxy` | nginx :8080 + Bearer |
| `monitoring` | node_exporter (опционально) |

## Безопасность

- Не публикуйте **11434** в интернет.
- Внешний доступ — только **8080** + токен (Vault).
- Не коммитьте: `certs/*.pem`, `.vault_pass`, `inventory/hosts.yml`.

## Проверка без GPU

```bash
ansible-playbook playbooks/stage1.yml --syntax-check
```

## Структура репозитория

```text
playbooks/stage1.yml              # точка входа
inventory/group_vars/gpu_llm/   # vars.yml + vault.yml
docs/verification.md            # отчёт / внешняя проверка
docs/stage1-gpu-vm.md           # чеклист развёртывания
roles/                          # common, nvidia, docker, ollama, ...
```

## Лицензия

MIT
