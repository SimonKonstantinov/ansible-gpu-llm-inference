# Ansible Vault — токен reverse proxy

Секрет `vault_reverse_proxy_api_token` хранится в зашифрованном  
`inventory/group_vars/gpu_llm/vault.yml`. Пароль vault — только у вас (файл `.vault_pass`, в git не попадает).

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
```

## Playbook с vault

```bash
ansible-playbook playbooks/stage1.yml --tags proxy --vault-password-file .vault_pass
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
ansible-playbook playbooks/stage1.yml --tags proxy --vault-password-file .vault_pass
```

## Важно

- Не коммитьте `.vault_pass` и `.pem`.
- Зашифрованный `vault.yml` **можно** коммитить в git — без пароля vault он бесполезен.
- Пароль vault храните в менеджере паролей; для CI — секрет в GitHub Actions.
