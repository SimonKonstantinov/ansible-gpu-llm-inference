# Проверка развёртывания

Полная инструкция для сдачи тестового задания — в **[SUBMISSION.md](SUBMISSION.md)** (чеклист, команды, скриншоты).

Кратко:

```bash
ansible-playbook playbooks/stage1.yml --tags verify --vault-password-file .vault_pass
```

Ожидание: **PLAY RECAP** `failed=0`.

Скриншоты: [screenshots/README.md](screenshots/README.md).
