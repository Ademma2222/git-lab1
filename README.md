# Docker Compose, KVM и Ansible

Небольшое приложение из двух сервисов: фронтенд на nginx и бэкенд на Flask. Страница при загрузке запрашивает `/api/hello`, nginx проксирует запрос на бэкенд, ответ выводится на странице.

## Схема

```
ноутбук (браузер) -> WSL2 (SSH-туннель) -> VM в KVM -> Docker Compose -> frontend (nginx) -> backend (Flask)
```

Адреса:

- локально: http://localhost:8080
- с ноутбука через VM: http://localhost:8081

## Запуск локально

```
docker compose up -d --build
```

Проверка:

```
curl http://localhost:8080/api/hello
```

## KVM в WSL

Проверка, что KVM доступен:

```
uname -r
ls -l /dev/kvm
virsh -c qemu:///system list --all
```

VM создаётся скриптом `vm/create-vm.sh` (Ubuntu 24.04 cloud image, SSH-ключ добавляется через cloud-init). IP машины:

```
virsh -c qemu:///system domifaddr lab-vm
```

Проброс порта на ноутбук:

```
ssh -N -L 0.0.0.0:8081:localhost:8080 ubuntu@<IP-VM>
```

## Ansible

IP виртуальной машины нужно указать в `ansible/inventory.ini`.

```
sudo apt install -y ansible rsync
ansible-galaxy collection install community.docker ansible.posix
ansible -i ansible/inventory.ini lab -m ping
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

Playbook устанавливает Docker, копирует `backend`, `frontend` и `compose.yaml` в `/opt/lab` и запускает Compose. Повторный запуск проходит без изменений (`changed=0`, `failed=0`).

## Проверка связи фронтенда с бэкендом

```
curl http://localhost:8080/api/hello
curl http://localhost:8081/api/hello
docker compose ps
```

Первая команда выполняется на VM или локально, вторая на ноутбуке при открытом туннеле. Бэкенд должен вернуть `{"message":"Привет от бэкенда!"}`.

## Trivy

Workflow `.github/workflows/trivy.yml` собирает образы из `compose.yaml` и сканирует их с помощью Trivy. Результат виден в логе запуска во вкладке Actions.
