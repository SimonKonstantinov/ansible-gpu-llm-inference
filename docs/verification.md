# Что поднято и как проверить

Инструкция для сдачи **этапа 1**: Ansible на GPU-ВМ, self-hosted LLM API.

## 1. Что развёрнуто

| Компонент | Описание |
|-----------|----------|
| Площадка | GPU-ВМ [immers.cloud](https://immers.cloud), Ubuntu 22.04, 1× RTX 4090 |
| Автоматизация | Ansible [`playbooks/stage1.yml`](../playbooks/stage1.yml) |
| NVIDIA | Драйвер, проверка `nvidia-smi` |
| Docker | Docker + NVIDIA Container Toolkit, smoke-тест GPU в контейнере |
| LLM | **Ollama** в Docker, модель **`qwen2.5:7b`** (Q4_K_M) |
| Автозапуск | systemd unit `ollama-compose.service` |
| API на ВМ | Ollama `http://127.0.0.1:11434` |
| Внешний доступ | **nginx** на порту **8080**, **Bearer token** (секрет в Ansible Vault) |
| SSH | Пользователь `ansible`, ключ в `certs/` (не в git) |

Control node — локальный ПК: `ansible-playbook` по SSH на GPU-ВМ.

## 2. Развёртывание (кратко)

```bash
cd ~/ansible-gpu-llm-inference
ansible-galaxy collection install -r requirements.yml
# inventory/hosts.yml — IP ВМ, user ansible, путь к .pem

ansible-playbook playbooks/stage1.yml --tags base,nvidia,docker,ollama
ansible-playbook playbooks/stage1.yml --tags models
ansible-playbook playbooks/stage1.yml --tags verify

# внешний API через nginx + Vault:
ansible-playbook playbooks/stage1.yml --tags proxy,base --vault-password-file .vault_pass
```

- Переменные: [`inventory/group_vars/gpu_llm/vars.yml`](../inventory/group_vars/gpu_llm/vars.yml)
- Секрет токена: `inventory/group_vars/gpu_llm/vault.yml` (зашифрован)
- Пароль vault: локальный `.vault_pass` — см. [vault-setup.md](vault-setup.md)

Подробный чеклист: [stage1-gpu-vm.md](stage1-gpu-vm.md).

## 3. Проверка

### 3.1. Ansible (control node)

```bash
ansible gpu_llm -m ping
ansible-playbook playbooks/stage1.yml --tags verify --vault-password-file .vault_pass
```

### 3.2. На GPU-ВМ (SSH)

```bash
ssh -i certs/your-private-key.pem ansible@YOUR_VM_IP
nvidia-smi
docker ps
curl -s http://127.0.0.1:11434/api/tags
systemctl is-enabled ollama-compose
```

### 3.3. Снаружи через браузер (расширение DevHeader)

Для проверки с белого IP использовалось расширение **DevHeader** (добавление HTTP-заголовков).

1. Установить **DevHeader** в браузере.
2. Добавить заголовок:
   - **Name:** `Authorization`
   - **Value:** `Bearer <токен>`
3. Токен на ПК:

   ```bash
   ansible-vault view inventory/group_vars/gpu_llm/vault.yml --vault-password-file .vault_pass
   ```

   Скопировать `vault_reverse_proxy_api_token`.

4. Включить правило DevHeader для вкладки.
5. Открыть в адресной строке:

   ```text
   http://YOUR_VM_IP:8080/api/tags
   ```

**Ожидаемый результат:** JSON со списком моделей, например `qwen2.5:7b`:

```json
{"models":[{"name":"qwen2.5:7b","model":"qwen2.5:7b",...,"quantization_level":"Q4_K_M",...}]}
```

6. **Chat (POST)** — через **F12 → Console**:

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
   })
     .then((r) => r.json())
     .then(console.log);
   ```

В ответе — поле `message.content` с текстом модели.

### 3.4. curl (альтернатива)

```bash
TOKEN=$(ansible-vault view inventory/group_vars/gpu_llm/vault.yml --vault-password-file .vault_pass \
  | awk -F'"' '/vault_reverse_proxy_api_token/{print $2}')

curl -s "http://YOUR_VM_IP:8080/api/tags" -H "Authorization: Bearer ${TOKEN}"
```

### 3.5. SSH-туннель (без токена, только localhost Ollama)

```bash
ssh -i certs/your-private-key.pem -L 11434:127.0.0.1:11434 ansible@YOUR_VM_IP
```

В браузере: `http://127.0.0.1:11434/api/tags` (nginx и Bearer не используются).

## 4. Критерии приёмки (этап 1)

- Драйверы NVIDIA / `nvidia-smi`
- Docker + GPU в контейнерах
- Ollama с API и автозапуском
- Healthcheck (`verify`, `/api/tags`)
- Пример внешнего запроса (DevHeader или curl на `:8080`)
- README и playbook в репозитории

## 5. Безопасность

- Порт **11434** не публикуется в интернет.
- **8080** защищён Bearer-токеном (Vault).
- Не коммитить: `.pem`, `.vault_pass`, `inventory/hosts.yml`.

## 6. После проверки

Остановите или удалите ВМ в панели immers.

## Материалы для отчёта

- Скрин: DevHeader + URL `http://<IP>:8080/api/tags` + JSON с `qwen2.5:7b`
- Скрин или лог: `ansible-playbook playbooks/stage1.yml --tags verify`
- По желанию: `nvidia-smi` на ВМ
