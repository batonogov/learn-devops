# Talos

## Что такое Talos?

[Talos Linux](https://www.talos.dev/) — это **Linux**, разработанный для [Kubernetes](https://kubernetes.io/): безопасный, неизменяемый и минималистичный.

- Поддерживает **облачные платформы, «голое железо» и платформы виртуализации**
- Все **управление системой осуществляется через API**. Нет SSH, оболочки или консоли
- Готовность к работе: **поддерживает одни из крупнейших Kubernetes-кластеров в мире**
- Проект с открытым исходным кодом от команды [Sidero Labs](https://www.siderolabs.com/)

## Почему Talos

Имея меньше, Talos предлагает больше: безопасность, эффективность, устойчивость, согласованность.

Все эти аспекты улучшаются благодаря простоте и минимализму.

## Загрузка Talos на физический сервер с использованием ISO

Talos может быть установлен на физическую машину с использованием ISO-образа. ISO-образы для архитектур amd64 и arm64 доступны на [странице релизов Talos](https://github.com/siderolabs/talos/releases/).

Talos не устанавливается на диск при загрузке с ISO до тех пор, пока не будет применена конфигурация машины.

Пожалуйста, следуйте [руководству по началу работы](https://www.talos.dev/v1.9/introduction/getting-started/) для выполнения общих шагов по установке Talos.

Примечание: Если на диске уже установлена Talos, при загрузке с ISO Talos загрузится с этой установленной версии.
Порядок загрузки должен отдавать предпочтение диску перед ISO, либо ISO должно быть удалено после установки, чтобы Talos загружался с диска.

Ознакомьтесь со справочником по [параметрам ядра](https://www.talos.dev/v1.9/reference/kernel/) для списка поддерживаемых Talos параметров ядра.

Доступны два типа ISO-образов:

- metal-arch.iso: поддерживает загрузку на системах с BIOS и UEFI (для x86), только UEFI для arm64.
- metal-arch-secureboot.iso: поддерживает загрузку только на системах с UEFI в режиме SecureBoot (создано с помощью [Image Factory](https://www.talos.dev/v1.9/learn-more/image-factory/).

## Начало работы

Руководство по настройке кластера Talos Linux.

Этот документ проведет вас через процесс установки простого кластера Talos, а также объяснит некоторые ключевые концепции.

Независимо от того, где вы запускаете Talos, этапы создания Kubernetes-кластера включают:

1. Загрузка машин с образа Talos Linux.
2. Определение конечной точки API Kubernetes и создание конфигурации машин.
3. Настройка Talos Linux путем применения конфигураций машин.
4. Настройка `talosctl`.
5. Запуск Kubernetes.

## Производственный кластер

Для высокодоступного Kubernetes-кластера в продакшене рекомендуется использовать три узла плоскости управления.
Использование пяти узлов может обеспечить большую устойчивость к сбоям,
но также приводит к большему количеству операций репликации и может отрицательно сказаться на производительности.

### Layer 2 VIP (общий IP-адрес)

Talos имеет встроенную поддержку работы Kubernetes через общий/виртуальный IP-адрес.
Для этого требуется соединение уровня 2 (Layer 2) между узлами управляющей плоскости.

Выберите неиспользуемый IP-адрес в той же подсети, что и узлы плоскости управления, для использования в качестве VIP.
(Убедитесь, что выделенный адрес не используется другими устройствами и исключен из диапазона DHCP.)

### Выделение секретов

При создании конфигурационных файлов для кластера Talos Linux рекомендуется начать с генерации файлы с секретами,
который должен быть сохранен в безопасном месте.
Этот файл можно использовать для генерации конфигураций машин или клиентов в любое время:

```sh
talosctl gen secrets -o secrets.yaml
```

### Запускаем Talos

Теперь мы можем создать общую конфигурацию машин:

```sh
talosctl gen config --kubernetes-version 1.31.4 --with-secrets secrets.yaml my-cluster https://172.16.61.10:6443 --config-patch @patch.yaml
```

Создаем конфигурацию для каждого узла:

```sh
talosctl machineconfig patch controlplane.yaml --patch @cp0.patch --output cp0.yaml
talosctl machineconfig patch controlplane.yaml --patch @cp1.patch --output cp1.yaml
talosctl machineconfig patch controlplane.yaml --patch @cp2.patch --output cp2.yaml
talosctl machineconfig patch worker.yaml --patch @worker0.patch --output worker0.yaml
talosctl machineconfig patch worker.yaml --patch @worker1.patch --output worker1.yaml
talosctl machineconfig patch worker.yaml --patch @worker2.patch --output worker2.yaml
```

```sh
talosctl apply-config --insecure -n 172.16.61.144 --file ./cp0.yaml
talosctl apply-config --insecure -n 172.16.61.145 --file ./cp1.yaml
talosctl apply-config --insecure -n 172.16.61.146 --file ./cp2.yaml
talosctl apply-config --insecure -n 172.16.61.147 --file ./worker0.yaml
talosctl apply-config --insecure -n 172.16.61.149 --file ./worker1.yaml
talosctl apply-config --insecure -n 172.16.61.148 --file ./worker2.yaml
```

После перезапуска Controls Plane узла необходимо инициализировать etcd:

```sh
talosctl bootstrap --nodes 172.16.61.11 --endpoints 172.16.61.11 --talosconfig=./talosconfig
```

Получаем kube config:

```sh
talosctl kubeconfig ~/.kube/config --nodes 172.16.61.10 --endpoints 172.16.61.10 --talosconfig ./talosconfig
```

## Настройка Cilium

Добавляем репозиторий:

```sh
helm repo add cilium https://helm.cilium.io/
helm repo update
```

Устанавливаем Cilium:

```sh
helm upgrade \
    --install \
    cilium \
    cilium/cilium \
    --version 1.16.5 \
    --namespace kube-system \
    --values cilium/values.yaml
```

## Metrics Server

Устанавливаем Metrics Server

```sh
helm upgrade \
  --namespace kube-system \
  --install metrics-server metrics-server/metrics-server \
  --set args={--kubelet-insecure-tls}
```

Поднимаем **Traefik Kubernetes Ingress**

```sh
helm upgrade \
  --install \
  --namespace traefik \
  --create-namespace \
  traefik traefik/traefik \
  --values traefik/values.yaml
```

Обновление кластера

```sh
talosctl --nodes 172.16.61.10 upgrade-k8s --to 1.32.0
```
