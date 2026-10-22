# Улучшения архитектуры (этап 1)

> **Основной документ для сдачи:** [SUBMISSION.md](SUBMISSION.md). Этот файл — дополнительное описание слоёв, не обязательное для проверки ТЗ.

Краткое описание слоёв для тестового задания: разделение API, observability и секретов.

## Слои

```text
                         Internet
                             |
        +--------------------+--------------------+
        |                    |                    |
   :8080 Bearer        :8082 Basic Auth    :8081 Basic Auth
        |                    |                    |
     nginx               nginx               nginx
        |                    |                    |
   Ollama :11434      Open WebUI :8088     Grafana :3000
   (localhost)              |                    |
        ^                    |               Prometheus
        +--------------------+                    |
                         node_exporter + dcgm-exporter
```

### API (инференс)

- Ollama слушает только **127.0.0.1:11434**.
- Внешний доступ — **nginx :8080** и статический **Bearer**-токен из Vault.
- Минимальная поверхность атаки: отдельные порты и механизмы auth для API, чата и метрик.

### Chat UI

- **Open WebUI** на localhost, снаружи **nginx :8082** + basic auth (Vault).
- UI ходит в Ollama через `host.docker.internal` — порт 11434 не публикуется.
- См. [open-webui.md](open-webui.md).

### Observability

- Метрики хоста и GPU собираются в **Prometheus** (localhost).
- **Grafana** читает Prometheus; UI не публикуется напрямую.
- Второй vhost nginx (**8081**) с отдельными учётными данными basic auth (тоже Vault).
- Разделение портов и механизмов auth: API-токен ≠ пароль мониторинга.

### Секреты

- Все чувствительные значения в **Ansible Vault** (`vault.yml`), пароль vault локально (`.vault_pass`, не в git).
- В репозитории — только зашифрованный vault и примеры (`vault.yml.example`).
- IaC: повторяемое развёртывание через `ansible-playbook`, без ручной настройки на ВМ.

## Дальнейшие шаги (вне PoC)

- TLS (Let's Encrypt или корпоративный сертификат) на 8080/8081/8082.
- Ограничение UFW для внешних портов по IP.
- Alertmanager + правила по GPU/диску.
- Централизованный Loki для логов Ollama/nginx.

Подробности мониторинга: [monitoring.md](monitoring.md).
