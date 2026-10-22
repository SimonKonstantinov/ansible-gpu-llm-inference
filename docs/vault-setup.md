# Ansible Vault — секреты API, Grafana и Open WebUI

**Куда какой логин и пароль:** полная таблица в [access-credentials.md](access-credentials.md).

В зашифрованном `inventory/group_vars/gpu_llm/vault.yml` хранятся:

| Ключ vault | Куда ведёт |
|------------|------------|
| `vault_reverse_proxy_api_token` | **:8080** — заголовок `Authorization: Bearer …` (API Ollama) |
| `vault_grafana_nginx_password` | **:8081** — nginx basic auth, логин `monitor` |
| `vault_grafana_admin_password` | **:8081** — после nginx, вход в Grafana, логин `admin` |
| `vault_open_webui_nginx_password` | **:8082** — nginx basic auth, логин `chat` |

Учётная запись **внутри** Open WebUI (email/пароль в UI) в Vault **не** хранится — создаётся при первом визите на :8082.

Пароль **файла** vault — только у вас (`.vault_pass`, в git не попадает).

## Первый запуск (уже настроено на машине разработки)

Если файла `vault.yml` нет:

```bash
cd ~/ansible-gpu-llm-inference
openssl rand -hex 32 > /tmp/token.txt
ansible-vault create inventory/group_vars/gpu_llm/vault.yml --vault-password-file .vault_pass
```

Содержимое vault (перед шифрованием):

```yaml
---
vault_reverse_proxy_api_token: "ВСТАВЬТЕ_ТОКЕН"
vault_grafana_admin_password: "ВСТАВЬТЕ_ПАРОЛЬ_GRAFANA"
vault_grafana_nginx_password: "ВСТАВЬТЕ_ПАРОЛЬ_NGINX_BASIC"
vault_open_webui_nginx_password: "ВСТАВЬТЕ_ПАРОЛЬ_WEBUI"
```

Пример без шифрования: [`inventory/group_vars/vault.yml.example`](../inventory/group_vars/vault.yml.example).

## Playbook с vault

```bash
ansible-playbook playbooks/stage1.yml --tags proxy,monitoring --vault-password-file .vault_pass
```

Или ввести пароль вручную:

```bash
ansible-playbook playbooks/stage1.yml --tags proxy --ask-vault-pass
```

## Включить внешний API

В `inventory/group_vars/gpu_llm/vars.yml`:

```yaml
enable_reverse_proxy: true
```

## Проверка снаружи

```bash
source .vault_pass  # не делайте так — используйте переменную:
# токен смотрите: ansible-vault view inventory/group_vars/gpu_llm/vault.yml --vault-password-file .vault_pass

curl -s "http://YOUR_VM_IP:8080/api/tags" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Сменить токен

```bash
ansible-vault edit inventory/group_vars/gpu_llm/vault.yml --vault-password-file .vault_pass
ansible-playbook playbooks/stage1.yml --tags proxy,monitoring --vault-password-file .vault_pass
```

## Важно

- Не коммитьте `.vault_pass` и `.pem`.
- Зашифрованный `vault.yml` **можно** коммитить в git — без пароля vault он бесполезен.
- Пароль vault храните в менеджере паролей; для CI — секрет в GitHub Actions.
