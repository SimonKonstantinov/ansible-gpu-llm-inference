#!/usr/bin/env bash
# Запуск на GPU-ВМ от root: создаёт пользователя ansible для Ansible playbook.
set -euo pipefail

ANSIBLE_USER="${ANSIBLE_USER:-ansible}"
PUBKEY_FILE="${1:-}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Запустите от root: sudo bash $0 [path/to/id_rsa.pub]"
  exit 1
fi

if ! id "${ANSIBLE_USER}" &>/dev/null; then
  useradd -m -s /bin/bash "${ANSIBLE_USER}"
  echo "Создан пользователь ${ANSIBLE_USER}"
else
  echo "Пользователь ${ANSIBLE_USER} уже существует"
fi

usermod -aG sudo "${ANSIBLE_USER}" 2>/dev/null || usermod -aG wheel "${ANSIBLE_USER}" 2>/dev/null || true
echo "${ANSIBLE_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${ANSIBLE_USER}"
chmod 440 "/etc/sudoers.d/${ANSIBLE_USER}"

install -d -m 700 -o "${ANSIBLE_USER}" -g "${ANSIBLE_USER}" "/home/${ANSIBLE_USER}/.ssh"
AUTH_KEYS="/home/${ANSIBLE_USER}/.ssh/authorized_keys"

if [[ -n "${PUBKEY_FILE}" && -f "${PUBKEY_FILE}" ]]; then
  grep -qF "$(cat "${PUBKEY_FILE}")" "${AUTH_KEYS}" 2>/dev/null || cat "${PUBKEY_FILE}" >> "${AUTH_KEYS}"
elif [[ ! -s "${AUTH_KEYS}" ]]; then
  echo "Укажите публичный ключ:"
  echo "  На ПК: ssh-keygen -y -f certs/your-private-key.pem > ansible.pub"
  echo "  scp ansible.pub root@VM:/tmp/ && $0 /tmp/ansible.pub"
  exit 1
fi

chown "${ANSIBLE_USER}:${ANSIBLE_USER}" "${AUTH_KEYS}"
chmod 600 "${AUTH_KEYS}"

echo "Готово. Проверка: ssh -i your.pem ${ANSIBLE_USER}@$(hostname -I | awk '{print $1}') whoami"
