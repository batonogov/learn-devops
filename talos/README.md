# Talos

## Что такое Талос?

Talos - это дистрибутив Linux, оптимизированный для контейнеров;
переосмысление Linux для распределенных систем, таких как Kubernetes.
Разработанный, чтобы быть максимально минимальным, сохраняя при этом практичность.
По этим причинам Talos имеет ряд уникальных для него особенностей:

- неизменяесый
- атомарный
- эфимерный
- минималистичный
- по умолчанию он безопасен
- управляется с помощью одного декларативного файла конфигурации и gRPC API
- Talos может быть развернут в контейнерных, облачных, виртуализированных и голых металлических платформах.

## Почему Талос

Имея меньше, Талос предлагает больше. Безопасность. Эффективность. Устойчивость. Последовательность.

Все эти области улучшаются просто за счет того, что у них меньше.

## Загрузка Talos на голом металле с ISO

Talos не устанавливается на диск при загрузке из ISO до тех пор, пока не будет применена конфигурация машины.

## Настройка Talos Linux

Определяем переменную с IP адресом Control Plane узла:

```sh
export TALOS_CONTROL_PLANE_IP=192.168.1.48
```

Вот так можно посмотреть список дисков на узле:

```sh
talosctl -n $TALOS_CONTROL_PLANE_IP get disks --insecure
```

Генерируем конфиг

```sh
talosctl gen config --kubernetes-version 1.32.0 talos https://$TALOS_CONTROL_PLANE_IP:6443 --config-patch @patch.yaml
```

Применяем конфигурацию

```sh
talosctl apply-config --insecure -n $TALOS_CONTROL_PLANE_IP --file ./controlplane.yaml
```

После перезапуска Controls Plane узла необходимо инициализировать etcd:

```sh
talosctl bootstrap --nodes $TALOS_CONTROL_PLANE_IP --endpoints $TALOS_CONTROL_PLANE_IP --talosconfig=./talosconfig
```

Получаем kube config:

```sh
talosctl kubeconfig ~/.kube/config --nodes $TALOS_CONTROL_PLANE_IP --endpoints $TALOS_CONTROL_PLANE_IP --talosconfig ./talosconfig
```

Добавляем рабочий узел:

```sh
export TALOS_WORKER_1_IP=192.168.1.142
talosctl apply-config --insecure -n $TALOS_WORKER_1_IP --file ./worker.yaml
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
    --values cilium.yaml
```

## Metrics Server

Устанавливаем Metrics Server

```sh
helm upgrade \
  --namespace kube-system \
  --install metrics-server metrics-server/metrics-server \
  --set args={--kubelet-insecure-tls}
```

```sh
talosctl upgrade-k8s --nodes $TALOS_CONTROL_PLANE_IP --to 1.32.1
```
