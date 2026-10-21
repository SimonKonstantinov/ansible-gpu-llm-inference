# Создание пользователя `ansible` на GPU-ВМ

Playbook рассчитан на SSH под пользователем **`ansible`** с ключом из `certs/your-private-key.pem`.

Сначала зайдите на ВМ под **`ubuntu`** — immers часто выдаёт **пароль в панели** (а не вход по `.pem` с первого раза).

```bash
ssh ubuntu@YOUR_VM_IP
# введите пароль из личного кабинета immers (раздел сервера / доступ)
```

Если `ssh -i certs/....pem ubuntu@IP` всё равно просит пароль — ключ ещё не добавлен в `authorized_keys`; это ожидаемо, входите по паролю и настройте ключ ниже.

Зайти под **root** можно только если immers это разрешил; иначе все шаги — от `ubuntu` через `sudo`.

## Вариант A: один скрипт (от root)

Скопируйте на сервер и выполните:

```bash
# на сервере, от root
bash bootstrap-ansible-user.sh
```

Файл скрипта в репозитории: [`scripts/bootstrap-ansible-user.sh`](../scripts/bootstrap-ansible-user.sh).

Перед запуском откройте скрипт и вставьте **публичный** ключ (см. ниже), если не используете автогенерацию из `.pem`.

## Сначала: привязать ваш `.pem` к `ubuntu` (один раз, по паролю)

На **ПК**:

```bash
cd ~/ansible-gpu-llm-inference
ssh-keygen -y -f certs/your-private-key.pem > /tmp/ansible.pub
```

На **сервере** (уже вошли как `ubuntu` по паролю):

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys   # вставить одну строку из /tmp/ansible.pub
chmod 600 ~/.ssh/authorized_keys
```

Проверка с ПК (пароль больше не нужен):

```bash
ssh -i certs/your-private-key.pem ubuntu@YOUR_VM_IP whoami
```

Дальше создайте пользователя `ansible` (вариант B) **или** временно используйте `ubuntu` в inventory (см. конец файла).

## Вариант B: команды вручную (от root или `sudo`)

```bash
# от ubuntu:
sudo -i   # или каждая команда с sudo

# 1. Пользователь и sudo без пароля (нужно Ansible)
useradd -m -s /bin/bash ansible
usermod -aG sudo ansible
echo 'ansible ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible
chmod 440 /etc/sudoers.d/ansible

# 2. SSH-каталог
install -d -m 700 -o ansible -g ansible /home/ansible/.ssh

# 3. Публичный ключ (получить на ПК с репозиторием):
#    ssh-keygen -y -f certs/your-private-key.pem
# Вставить вывод в authorized_keys:
nano /home/ansible/.ssh/authorized_keys
chown ansible:ansible /home/ansible/.ssh/authorized_keys
chmod 600 /home/ansible/.ssh/authorized_keys
```

## Публичный ключ с вашего `.pem` (на control node)

```bash
cd ~/ansible-gpu-llm-inference
chmod 600 certs/your-private-key.pem
ssh-keygen -y -f certs/your-private-key.pem
```

Строка `ssh-rsa AAAA...` или `ssh-ed25519 ...` — целиком в `authorized_keys` пользователя `ansible`.

## Проверка

На ПК (из корня репозитория):

```bash
ssh -i certs/your-private-key.pem ansible@YOUR_VM_IP 'whoami && sudo nvidia-smi'
ansible gpu_llm -m ping
```

В `inventory/hosts.yml` укажите актуальный IP и путь к ключу **от корня репозитория**:

```yaml
ansible_ssh_private_key_file: certs/your-private-key.pem
```

Запускайте `ansible-playbook` из каталога `ansible-gpu-llm-inference`, не из `inventory/`.

## Если immers даёт только пользователя `ubuntu`

**Вариант 1 (рекомендуется):** после настройки ключа создать `ansible` (вариант B).

**Вариант 2 (быстро):** в `inventory/hosts.yml`:

```yaml
ansible_user: ubuntu
ansible_ssh_private_key_file: certs/your-private-key.pem
```

Playbook использует `become: true` — для `ubuntu` в sudoers обычно нужен пароль. Тогда один прогон:

```bash
ansible-playbook playbooks/stage1.yml --ask-become-pass
# пароль тот же, что для SSH ubuntu (если immers один пароль на ВМ)
```

Или отключить запрос sudo-пароля для ubuntu (только на тестовой ВМ):

```bash
echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ubuntu-nopasswd
sudo chmod 440 /etc/sudoers.d/ubuntu-nopasswd
```

После этого `ansible-playbook` без `--ask-become-pass`.
