# Логины, пароли и куда они ведут

Краткая шпаргалка для сдачи ТЗ и ручной проверки. Все секреты из Ansible Vault лежат в  
`inventory/group_vars/gpu_llm/vault.yml` (расшифровка — только у вас, файл `.vault_pass`).

Посмотреть значения:

```bash
ansible-vault view inventory/group_vars/gpu_llm/vault.yml --vault-password-file .vault_pass
```

Имена пользователей nginx можно переопределить в `inventory/group_vars/gpu_llm/vars.yml`  
(по умолчанию — как в таблице ниже).

---

## Сводная таблица (доступ с интернета)

| Куда заходите | URL (пример) | Тип входа | Логин | Пароль / секрет | Ключ в Vault |
|---------------|--------------|-----------|-------|-----------------|--------------|
| **LLM API** (Ollama) | `http://YOUR_VM_IP:8080/api/tags` | HTTP Bearer (не логин в браузере) | — | токен в заголовке `Authorization: Bearer …` | `vault_reverse_proxy_api_token` |
| **Grafana** (GPU-дашборды) | `http://YOUR_VM_IP:8081` | Два шага (см. ниже) | см. ниже | см. ниже | см. ниже |
| **Open WebUI** (чат с моделью) | `http://YOUR_VM_IP:8082` | Вход в Open WebUI (см. ниже) | email в UI | пароль в UI | см. ниже |

Сервисы **не** слушают интернет напрямую: снаружи только nginx на портах **8080**, **8081**, **8082**.

---

## Порт 8080 — API Ollama (программный доступ)

**Назначение:** запросы к модели из curl, Postman, DevHeader, своего кода.

| Поле | Значение |
|------|----------|
| URL | `http://YOUR_VM_IP:8080` (пути как у Ollama: `/api/tags`, `/api/chat`, `/v1/chat/completions`) |
| Логин | нет |
| Пароль | нет |
| Секрет | **токен** из `vault_reverse_proxy_api_token` |
| Как передать | заголовок `Authorization: Bearer <токен>` |

Пример:

```bash
curl -s "http://YOUR_VM_IP:8080/api/tags" \
  -H "Authorization: Bearer ВАШ_ТОКЕН_ИЗ_VAULT"
```

В браузере без заголовка будет **401** — это ожидаемо.

---

## Порт 8081 — Grafana (мониторинг GPU)

**Назначение:** графики загрузки GPU, памяти, температуры (дашборд **GPU DCGM**). Это **не** чат с нейросетью.

### Важно: два разных окна входа

| Шаг | Что видите в браузере | Логин | Пароль из vault |
|-----|------------------------|-------|-----------------|
| **1** | Системное окно «Вход на сайт» / Basic Auth (сразу после открытия `:8081`) | **`monitor`** | **`vault_grafana_nginx_password`** |
| **2** | Страница Grafana (логотип Grafana) | **`admin`** | **`vault_grafana_admin_password`** |

На **шаге 1** логин **`admin` не подойдёт** — будет снова запрос пароля или «неверный логин».  
Пароль от шага 2 (`vault_grafana_admin_password`) на шаге 1 **тоже не подойдёт**.

Копируйте пароль из `ansible-vault view` **без кавычек** `"..."` вокруг значения.

Проверка с вашего ПК (пароль не показывается):

```bash
chmod +x scripts/verify-grafana-step1.sh
./scripts/verify-grafana-step1.sh YOUR_VM_IP
```

Если скрипт пишет OK, а браузер не пускает — откройте `:8081` в **режиме инкогнито** (часто сохранён старый неверный пароль).

### Шаг 1 — nginx Basic Auth

| Поле | Значение |
|------|----------|
| Логин | `monitor` |
| Пароль | `vault_grafana_nginx_password` |

### Шаг 2 — Grafana

| Поле | Значение |
|------|----------|
| Логин | `admin` |
| Пароль | `vault_grafana_admin_password` |

---

## Порт 8082 — Open WebUI (чат в браузере)

**Назначение:** диалог с моделью `qwen2.5:7b` в веб-интерфейсе.

**Окна nginx Basic Auth на :8082 нет** (по умолчанию `open_webui_nginx_basic_auth: false`).  
Иначе браузер бесконечно спрашивает пароль: SPA шлёт API-запросы без заголовка Basic Auth.

| Поле | Значение |
|------|----------|
| URL | `http://YOUR_VM_IP:8082` |
| Логин | email/имя, которые вы задали **в Open WebUI** |
| Пароль | пароль **в Open WebUI** (не из Vault) |

При **первом** визите создайте учётную запись в форме Open WebUI. Пароль `vault_open_webui_nginx_password` нужен только если вы вручную включите `open_webui_nginx_basic_auth: true` (не рекомендуется для браузера).

После входа выберите модель **qwen2.5:7b** и отправьте сообщение.

---

## Локально на ВМ (SSH, без nginx)

| Сервис | URL | Логин / пароль |
|--------|-----|----------------|
| Ollama API | `http://127.0.0.1:11434` | без auth (только с ВМ или через SSH-туннель) |
| Prometheus | `http://127.0.0.1:9090` | без auth |
| Grafana | `http://127.0.0.1:3000` | `admin` + `vault_grafana_admin_password` (без nginx basic) |
| Open WebUI | `http://127.0.0.1:8088` | только учётка Open WebUI (шаг 2 выше), без nginx basic |

---

## Соответствие Vault → переменные Ansible

| Ключ в `vault.yml` | Используется в |
|--------------------|----------------|
| `vault_reverse_proxy_api_token` | nginx :8080 → Ollama |
| `vault_grafana_nginx_password` | nginx :8081 (логин `monitor`) |
| `vault_grafana_admin_password` | Grafana UI (`admin`) |
| `vault_open_webui_nginx_password` | только если `open_webui_nginx_basic_auth: true` (обычно **не** используется) |

После смены секретов в vault:

```bash
ansible-playbook playbooks/stage1.yml --tags proxy --vault-password-file .vault_pass
```

---

## Частые ошибки

| Симптом | Причина |
|---------|---------|
| 401 на `:8080` в браузере | Нужен Bearer-токен, не логин/пароль |
| Не пускает на `:8081` / `:8082` | Проверьте basic auth nginx (`monitor` / `chat` и пароли из vault) |
| Пустой чат / нет моделей в WebUI | Модель не выбрана или Ollama не подтянул `qwen2.5:7b` (тег `models`) |
| Путаете Grafana и чат | **8081** — метрики GPU; **8082** — общение с моделью |

См. также: [verification.md](verification.md), [open-webui.md](open-webui.md), [monitoring.md](monitoring.md), [vault-setup.md](vault-setup.md).
