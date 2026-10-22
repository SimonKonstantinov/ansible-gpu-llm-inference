# Мониторинг (Prometheus + Grafana)

Снаружи доступна только **Grafana** на порту **8081** (nginx basic auth + вход admin). Экспортеры и Prometheus — на `127.0.0.1` на ВМ.

Отчёт для проверяющего: [SUBMISSION.md](SUBMISSION.md) (раздел «Мониторинг»).

## Компоненты

| Сервис | Порт (localhost) | Назначение |
|--------|------------------|------------|
| node_exporter | 9100 | CPU, RAM, диск, сеть |
| cAdvisor | 8089 | контейнеры Docker |
| nginx stub_status | 8090 | счётчики nginx |
| nginx-prometheus-exporter | 9113 | метрики nginx в Prometheus |
| ollama-exporter | 9420 | Ollama API / модели (`ollama_up`, `ollama_model_*`) |
| dcgm-exporter | 9400 | GPU |
| Prometheus | 9090 | сбор метрик |
| Grafana | 3000 | дашборды |

## Дашборды Grafana

| Папка | Дашборд |
|-------|---------|
| **GPU** | GPU DCGM |
| **Infrastructure** | Linux Host, Docker Containers, nginx |
| **LLM** | Ollama LLM Inference |

Включение: `enable_monitoring: true` и `enable_reverse_proxy: true` в `vars.yml`.

```bash
ansible-playbook playbooks/stage1.yml --tags monitoring --vault-password-file .vault_pass
```

Доступ: [access-credentials.md](access-credentials.md).

## Диагностика на ВМ

```bash
curl -s http://127.0.0.1:9090/-/ready
curl -s http://127.0.0.1:9420/metrics | grep ollama_up
curl -s http://127.0.0.1:9400/metrics | head
```

Compose: `/opt/monitoring/docker-compose.yml`.
