# Бюджетный прогон (immers.cloud, поминутная оплата)

## Этап 0 — без GPU-ВМ

1. Откройте [каталог моделей «можно попробовать»](https://immers.cloud/ai/model/?sort=-ICanTry).
2. Выберите модель (например **llama-3-8b-gpt-4o-ru1.0**).
3. Получите URL и ключ API в личном кабинете immers.
4. Выполните тестовый запрос — см. [immers-public-api.md](immers-public-api.md).

## Этап 1 — подготовка на ПК (бесплатно)

```bash
cd ansible-gpu-llm-inference
python3 -m pip install --user ansible ansible-lint yamllint
ansible-galaxy collection install -r requirements.yml
cp inventory/hosts.yml.example inventory/hosts.yml
# отредактируйте ansible_host и ansible_user
ansible-playbook playbooks/site.yml --syntax-check
```

## Этап 2 — GPU-ВМ immers

Рекомендуемый пресет: **rtx4090-1.8.32.160** (1× RTX 4090, 8 vCPU, 32 GB RAM, Ubuntu 22.04).

```bash
ansible-playbook playbooks/site.yml --tags base,nvidia,docker,ollama
ansible-playbook playbooks/site.yml --tags models
ansible-playbook playbooks/site.yml --tags verify
```

Повторный прогон без повторного `pull`: в `inventory/group_vars/gpu_llm.yml` установите `ollama_pull_models: false`.

## Этап 3 — проверка API

```bash
ansible-playbook playbooks/site.yml --tags verify
# или отдельный play:
ansible-playbook tests/verify.yml --tags verify
ssh ubuntu@<IP> 'curl -s http://127.0.0.1:11434/api/tags'
```

## Этап 4 — остановка

Остановите или удалите ВМ в панели immers, чтобы прекратить тарификацию.

Ориентир стоимости одного полного прогона: **~$1–2** при тарифе ~$0.93–1.0/ч и длительности 1–2 часа.
