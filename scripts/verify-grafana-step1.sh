#!/usr/bin/env bash
# Проверка шага 1 Grafana (:8081 nginx basic auth). Пароль не выводится.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

HOST="${1:-}"
if [[ -z "$HOST" ]]; then
  HOST=$(python3 -c "import yaml; print(yaml.safe_load(open('inventory/hosts.yml'))['all']['children']['gpu_llm']['hosts']['gpu01']['ansible_host'])")
fi

VAULT_FILE="inventory/group_vars/gpu_llm/vault.yml"
if [[ ! -f .vault_pass ]]; then
  echo "Нет .vault_pass в $ROOT"
  exit 1
fi

PASS=$(ansible-vault view "$VAULT_FILE" --vault-password-file .vault_pass \
  | python3 -c "import sys,yaml; print(yaml.safe_load(sys.stdin).get('vault_grafana_nginx_password',''))")

if [[ -z "$PASS" ]]; then
  echo "В vault нет vault_grafana_nginx_password"
  exit 1
fi

CODE_MONITOR=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 8 -u "monitor:${PASS}" "http://${HOST}:8081/" || echo "000")
CODE_ADMIN=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 8 -u "admin:${PASS}" "http://${HOST}:8081/" || echo "000")

echo "Проверка http://${HOST}:8081"
echo "  логин monitor + vault_grafana_nginx_password → HTTP ${CODE_MONITOR} (ожидается 200/302)"
echo "  логин admin  + тот же пароль              → HTTP ${CODE_ADMIN} (ожидается 401 — admin здесь не подходит)"
echo ""
if [[ "$CODE_MONITOR" =~ ^(200|302|307)$ ]]; then
  echo "OK: на шаге 1 используйте логин monitor и пароль vault_grafana_nginx_password (без кавычек)."
  echo "    Логин admin — только на шаге 2 (экран Grafana), с vault_grafana_admin_password."
  exit 0
fi
echo "FAIL: с вашего ПК basic auth не проходит. Варианты:"
echo "  1) Скопировали не тот ключ vault (нужен vault_grafana_nginx_password, не admin)."
echo "  2) После смены vault не прогнали: ansible-playbook playbooks/stage1.yml --tags proxy --vault-password-file .vault_pass"
echo "  3) Браузер запомнил старый пароль — режим инкогнито или сброс сохранённых паролей для :8081."
exit 1
