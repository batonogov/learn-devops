# Настройка kubernetes кластера после чистой установки при помощи **kubeadm**

## Создание ВМ

Наш кластер работает на 6 виртуальных машинах (3 control-plane и 3 node) и разворачивается с помощью [OpenTofu](../stepbystep/01istall-vm/opentofu/kubeadm-kanoe).

## Подготовка ВМ

Тестирование проводилось на **Ubuntu 24.04**

Подготавливаем ВМ при помощи [плейбука](../stepbystep/02install-k8s-kluster/ansible/kubeadm.yml)

Плейбук настроит все что нужно для работы **Kubernetes**.
Добавит необходимые **модули ядра**, установит **kubelet**, **kubeadm**, **kubectl**, **cri-o**... и перезапустит машинки если это необходимо.
Также произойдет инициализация кластера в HA режиме без **kube-proxy**.

Запускаем плейбук

```sh
ansible-playbook kubeadm.yml
```

Результат работы плейбука

```output
PLAY RECAP *******************************************************************************************************
kubeadm-cp-01              : ok=28   changed=23   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
kubeadm-cp-02              : ok=22   changed=17   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
kubeadm-cp-03              : ok=22   changed=17   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
kubeadm-node-01            : ok=13   changed=11   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
kubeadm-node-02            : ok=13   changed=11   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
kubeadm-node-03            : ok=13   changed=11   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

четверг 02 мая 2024  19:33:56 +0500 (0:00:02.841)       0:04:44.638 ***********
===============================================================================
Добавляю control-plane узлы в кластер ------------------------------------------------ 67.74s
Инициализирую высокодоступный кластер ------------------------------------------------ 50.23s
Устанавливаю пакеты kubelet, kubeadm, kubectl и cri-o -------------------------------- 44.44s
Добавляю репозитории Kubernetes и cri-o ---------------------------------------------- 14.60s
Устанавливаю нужные пакеты ----------------------------------------------------------- 13.38s
Добавляю node узлы в кластер --------------------------------------------------------- 11.06s
Устанавливаю пакеты ------------------------------------------------------------------- 7.83s
Предотвращаю обновление kubelet, kubeadm и kubectl ------------------------------------ 4.89s
Добавляю gpg ключ для репозиториев Kubernetes и cri-o --------------------------------- 4.74s
haproxy_static_pods : Наливаю конфигурацию keepalived --------------------------------- 4.62s
haproxy_static_pods : Создать директории /etc/kubernetes/manifests и /etc/keepalived -- 4.48s
Gathering Facts ----------------------------------------------------------------------- 4.44s
Включаю и запускаю службы kubelet и cri-o --------------------------------------------- 4.30s
upgrade_packages : Обновляю все пакеты до актуальных версий --------------------------- 4.20s
Gathering Facts ----------------------------------------------------------------------- 3.70s
haproxy_static_pods : Наливаю check_apiserver.sh -------------------------------------- 3.52s
haproxy_static_pods : Наливаю haproxy.cfg --------------------------------------------- 3.31s
haproxy_static_pods : Наливаю haproxy static pods manifest ---------------------------- 3.31s
haproxy_static_pods : Наливаю keepalived static pods manifest ------------------------- 3.23s
Добавляю модули br_netfilter и overlay ------------------------------------------------ 3.21s
```

``` Копирование и мерж ~/.kube/config
cp ~/.kube/config:~/.kube/configBcp
export KUBECONFIG=~/.kube/config:~/.kube/configLocal
kubectl config view --flatten > ~/.kube/config-merged
mv ~/.kube/config-merged ~/.kube/config
```


Если все прошло успешно, то можно перейти к [настройке CNI](README.md#%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0-cni).

## Инициализация кластера

Первый вариант подходит для тестирования, или создания не отказоустоичивого кластера,
Второй вариант создаст отказоустойчивый кластер готовый для прода.
Ansible Playbook создает второй вариант.

Дальше описаны варианты для понимания работы.

### Non HA (Подходит для тестирования, не рекомендуется для прода)

Для инициализации кластера запускаем на **control-plane** машинке команду

```sh
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

Команда инициализирует кластер Kubernetes с указанием диапазона подсети для сети плагина CNI (Container Network Interface).
В результате выполнения вы увидите лог выполнения и получите краткую инструкцию по дальнейшей работе.

В результате мы должны получить что-то подобное

```sh
kubectl get nodes -o wide
```

```output
NAME              STATUS   ROLES           AGE    VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
kubeadm-cp-01     Ready    control-plane   2m9s   v1.30.0   10.0.70.70    <none>        Ubuntu 22.04.4 LTS   5.15.0-105-generic   cri-o://1.30.0
kubeadm-node-01   Ready    <none>          27s    v1.30.0   10.0.70.71    <none>        Ubuntu 22.04.4 LTS   5.15.0-105-generic   cri-o://1.30.0
kubeadm-node-02   Ready    <none>          13s    v1.30.0   10.0.70.77    <none>        Ubuntu 22.04.4 LTS   5.15.0-105-generic   cri-o://1.30.0
```

### HA (Production Ready решение, рекомендуется)

Мы разместим **haproxy** и **keepalived** на **control-plane** узлах. Конфигурации налиты при помощи Ansible на этапе подготовки.
Наш виртуальный IP: **10.0.70.85:8888** для взаимодействия с **Kube Api Server**

Обратите внимание, что мы не устанавливаем **kube-proxy**, для этого мы указали ключ **--skip-phases=addon/kube-proxy**,
этот вариант подходит при использовании **Kubernetes** без **kube-proxy** и позволяет использовать **Cilium** для его полной замены.

Если вы планируете использовать **Flannel**, нужно оставить **kube-proxy**.

```sh
sudo kubeadm init \
    --pod-network-cidr=10.244.0.0/16 \
    --control-plane-endpoint=10.0.70.85:8888 \
    --upload-certs \
    --skip-phases=addon/kube-proxy
```

При успешном выполнении мы увидим примерно следующее

```output
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of the control-plane node running the following command on each as root:

  kubeadm join 10.0.70.85:8888 --token r120zn.za3vq0au6kzgoepu \
        --discovery-token-ca-cert-hash sha256:cacb3c674f63d7f261c4fed403f59ce6e7d4c869c3748e301c98b2b9f17f7786 \
        --control-plane --certificate-key 31ba08487b6899c2ebe43dd3857e168840a98d1077a7998c79f6f4838b4c08f7

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.0.70.85:8888 --token r120zn.za3vq0au6kzgoepu \
        --discovery-token-ca-cert-hash sha256:cacb3c674f63d7f261c4fed403f59ce6e7d4c869c3748e301c98b2b9f17f7786
```

Добавляем узлы и проверяем.

В результате мы должны получить что-то подобное

```sh
kubectl get nodes -o wide
```

```output
NAME              STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE           KERNEL-VERSION     CONTAINER-RUNTIME
kubeadm-cp-01     Ready    control-plane   46m   v1.30.0   10.0.70.70    <none>        Ubuntu 24.04 LTS   6.8.0-31-generic   cri-o://1.31.0
kubeadm-cp-02     Ready    control-plane   45m   v1.30.0   10.0.70.78    <none>        Ubuntu 24.04 LTS   6.8.0-31-generic   cri-o://1.31.0
kubeadm-cp-03     Ready    control-plane   45m   v1.30.0   10.0.70.79    <none>        Ubuntu 24.04 LTS   6.8.0-31-generic   cri-o://1.31.0
kubeadm-node-01   Ready    <none>          45m   v1.30.0   10.0.70.71    <none>        Ubuntu 24.04 LTS   6.8.0-31-generic   cri-o://1.31.0
kubeadm-node-02   Ready    <none>          45m   v1.30.0   10.0.70.77    <none>        Ubuntu 24.04 LTS   6.8.0-31-generic   cri-o://1.31.0
kubeadm-node-03   Ready    <none>          45m   v1.30.0   10.0.70.74    <none>        Ubuntu 24.04 LTS   6.8.0-31-generic   cri-o://1.31.0
```

## Настройка CNI

**CNI (Container Network Interface)** - это спецификация, которая определяет, как контейнеры в сети взаимодействуют друг с другом и с внешним миром.
Она позволяет плагинам сети в Kubernetes управлять сетевыми настройками контейнеров.

### Cilium

**Cilium** - это проект с открытым исходным кодом для обеспечения сетевого взаимодействия, безопасности и наблюдаемости для облачных сред,
таких как кластеры **Kubernetes** и другие платформы для оркестровки контейнеров.

В основе **Cilium** лежит новая технология ядра **Linux** под названием **eBPF**,
которая позволяет динамически вставлять в ядро Linux мощную логику управления безопасностью, видимостью и сетями.
**eBPF** используется для обеспечения высокопроизводительных сетей, мультикластерных и мультиоблачных возможностей,
расширенной балансировки нагрузки, прозрачного шифрования, широких возможностей сетевой безопасности, прозрачной наблюдаемости и многого другого.

Есть несколько вариантов установки **Cilium**

#### **Cilium CLI**

Установите последнюю версию **Cilium CLI**. **Cilium CLI** можно использовать для установки **Cilium**, проверки состояния установки **Cilium**,
а также для включения/выключения различных функций (например, кластерной сетки, Hubble).

```sh
brew install cilium-cli
```

Установите Cilium в кластер Kubernetes, на который указывает ваш текущий контекст kubectl:

```sh
cilium install --version 1.16.0
```

#### **Helm Chart**

Установка Cilium на кластер без kube-proxy

```sh
helm upgrade cilium cilium/cilium --version 1.16.0 \
    --namespace kube-system \
    --install \
    --values cilium/values.yaml
    
helm upgrade cilium cilium/cilium --version 1.17.5 \
    --namespace kube-system \
    --install --values values.yaml
```
```sh
cilium install \
--version v1.17.1 \
--set ipam.mode=kubernetes \
--set routingMode=native \
--set ipv4NativeRoutingCIDR="10.0.0.0/8" \
--set bgpControlPlane.enabled=true \
--set k8s.requireIPv4PodCIDR=true
```

После развертывания **Cilium** с помощью приведенного выше руководства мы можем сначала убедиться, что агент **Cilium** работает в нужном режиме:

```sh
kubectl -n kube-system exec ds/cilium -- cilium-dbg status | grep KubeProxyReplacement
```

Для получения подробной информации используйте --verbose:

```sh
kubectl -n kube-system exec ds/cilium -- cilium-dbg status --verbose
```

```output
KubeProxyReplacement Details:
  Status:                 True
  Socket LB:              Enabled
  Socket LB Tracing:      Enabled
  Socket LB Coverage:     Full
  Devices:                eth0   10.0.75.83 fe80::be24:11ff:fee9:819e (Direct Routing)
  Mode:                   SNAT
  Backend Selection:      Random
  Session Affinity:       Enabled
  Graceful Termination:   Enabled
  NAT46/64 Support:       Disabled
  XDP Acceleration:       Disabled
  Services:
  - ClusterIP:      Enabled
  - NodePort:       Enabled (Range: 30000-32767)
  - LoadBalancer:   Enabled
  - externalIPs:    Enabled
  - HostPort:       Enabled
```

Больше информации о работе без **kube-proxy** в [официальной документации](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/).

Проверяем статус установки

```sh
cilium status --wait
```

Мы должны увидеть что-то подобное

```output
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    disabled (using embedded mode)
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled

DaemonSet              cilium             Desired: 6, Ready: 6/6, Available: 6/6
Deployment             cilium-operator    Desired: 2, Ready: 2/2, Available: 2/2
Containers:            cilium             Running: 6
                       cilium-operator    Running: 2
Cluster Pods:          2/2 managed by Cilium
Helm chart version:
Image versions         cilium             quay.io/cilium/cilium:v1.15.6@sha256:6aa840986a3a9722cd967ef63248d675a87add7e1704740902d5d3162f0c0def: 6
                       cilium-operator    quay.io/cilium/operator-generic:v1.15.6@sha256:5789f0935eef96ad571e4f5565a8800d3a8fbb05265cf6909300cd82fd513c3d: 2
```

Выполните следующую команду, чтобы убедиться, что ваш кластер имеет правильное сетевое подключение (опционально):

```sh
cilium connectivity test
```

Пример вывода

```output
✅ [cilium-test] All 52 tests (600 actions) successful, 28 tests skipped, 0 scenarios skipped.
```

Можно удалить неймспейс **cilium-test**

```sh
kubectl delete namespaces cilium-test-1
```

## Установка тестового приложения

Для проверки работоспособности кластера установим **kube-prometheus-stack** при помощи **helm**

```sh
helm upgrade \
  --install \
  --namespace monitoring \
  --create-namespace \
  kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --values ./kube-prometheus-stack/values.yaml  \
  --version 61.3.2
```

Проверяем, что все запустилось

```sh
kubectl get pods -o wide -n monitoring
```

Должны увидеть

```output
NAME                                                        READY   STATUS    RESTARTS   AGE   IP           NODE              NOMINATED NODE   READINESS GATES
alertmanager-kube-prometheus-stack-alertmanager-0           2/2     Running   0          34s   10.244.2.5   kubeadm-node-02   <none>           <none>
kube-prometheus-stack-grafana-67997d8bd4-7s2fq              3/3     Running   0          50s   10.244.1.2   kubeadm-node-01   <none>           <none>
kube-prometheus-stack-kube-state-metrics-6fb5dddbdb-48l45   1/1     Running   0          50s   10.244.2.3   kubeadm-node-02   <none>           <none>
kube-prometheus-stack-operator-775b5fb784-gpn94             1/1     Running   0          50s   10.244.1.3   kubeadm-node-01   <none>           <none>
kube-prometheus-stack-prometheus-node-exporter-9d6ks        1/1     Running   0          50s   10.0.70.71   kubeadm-node-01   <none>           <none>
kube-prometheus-stack-prometheus-node-exporter-d74z8        1/1     Running   0          50s   10.0.70.77   kubeadm-node-02   <none>           <none>
kube-prometheus-stack-prometheus-node-exporter-fzgq2        1/1     Running   0          50s   10.0.70.70   kubeadm-cp-01     <none>           <none>
prometheus-kube-prometheus-stack-prometheus-0               2/2     Running   0          34s   10.244.2.6   kubeadm-node-02   <none>           <none>
```

Зайдем на веб интерфейс графаны

```sh
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 8000:80
```

Заходим на [localhost:8000](http://localhost:8000/login) и вводим

```grafana
Логин: admin
Пароль: prom-operator
```

## Настройка CSI

**CSI (Container Storage Interface)** - это спецификация, которая позволяет контейнерам в **Kubernetes** взаимодействовать с различными хранилищами данных,
такими как блочные и файловые системы, через стандартизированный интерфейс. Это позволяет управлять хранилищем данных более гибко и эффективно в среде контейнеров.

### **Longhorn**

Для организации системы хранения в кластере, мы будем использовать **[Longhorn](https://longhorn.io/)**.

**Longhorn** - это легкая, надежная и мощная система хранения распределенных блоков для **Kubernetes**.

**Longhorn** реализует распределенное блочное хранилище с помощью **контейнеров** и **микросервисов**.
**Longhorn** создает выделенный контроллер хранения для каждого тома блочного устройства и синхронно реплицирует том на несколько реплик,
хранящихся на нескол ьких узлах. Контроллер хранилища и реплики сами оркеструются с помощью **Kubernetes**.

#### Характеристики

- **Распределенное блочное хранилище** корпоративного класса без единой точки отказа
- **Инкрементный снимок** блочного хранилища
- Резервное копирование на вторичное хранилище (**NFS** или **S3-совместимое** объектное хранилище), основанное на эффективном обнаружении блоков изменений
- **Повторяющиеся снимки** и **резервное копирование**
- **Автоматизированное обновление без сбоев**. Вы можете обновить весь стек программного обеспечения **Longhorn**, не нарушая работу томов хранения.
- Интуитивно понятная приборная панель с **графическим интерфейсом**

#### Пререквизиты

- Кластер Kubernetes: Убедитесь, что каждый узел соответствует требованиям к установке.
- Ваша рабочая станция: Установите Helm версии 3.0 или более поздней.

#### Установка Longhorn

Примечание:

- Начальные настройки для **Longhorn** можно найти в пользовательских опциях **Helm** или отредактировав файл конфигурации развертывания.
- Для **Kubernetes** \< v1.25, если в вашем кластере все еще используется контроллер допуска Pod Security Policy, установите значение helm enablePSP в true,
  чтобы установить ресурс longhorn-psp PodSecurityPolicy, который позволит запускать привилегированные поды **Longhorn**.

#### Требования к установке

Каждый узел в кластере **Kubernetes**, на котором установлен **Longhorn**, должен отвечать следующим требованиям:

- Контейнерная среда выполнения, совместимая с Kubernetes (Docker v1.13+, containerd v1.3.7+ и т. д.)
- Kubernetes >= v1.21
- Установлен open-iscsi, и на всех узлах запущен демон iscsid.
  Это необходимо, поскольку Longhorn полагается на iscsiadm на узле для предоставления постоянных томов Kubernetes. Помощь в установке open-iscsi см. в [этом разделе](https://longhorn.io/docs/1.6.2/deploy/install/#installing-open-iscsi).
- Поддержка RWX требует, чтобы на каждом узле был установлен клиент NFSv4.
  Об установке клиента NFSv4 читайте в [этом разделе](https://longhorn.io/docs/1.6.2/deploy/install/#installing-nfsv4-client).
- Файловая система узла поддерживает функцию расширения файлов для хранения данных. В настоящее время мы поддерживаем:
  ext4
  XFS
- Должны быть установлены bash, curl, findmnt, grep, awk, blkid, lsblk.
- Распространение монтирования должно быть включено.

Рабочие нагрузки Longhorn должны иметь возможность запускаться от имени root, чтобы Longhorn был развернут и работал должным образом.

Этот сценарий можно использовать для проверки среды Longhorn на наличие потенциальных проблем.

Минимальное рекомендуемое аппаратное обеспечение см. в руководстве по передовому опыту.

1. Добавьте репозиторий Longhorn Helm:

   ```sh
   helm repo add longhorn https://charts.longhorn.io
   ```

1. Получите список последних чартов из репозитория:

   ```sh
   helm repo update
   ```

1. Установите Longhorn в пространстве имен longhorn-system.

   ```sh
   helm upgrade \
     --install \
     longhorn longhorn/longhorn \
     --namespace longhorn-system \
     --create-namespace \
     --version 1.6.2
   ```

1. Чтобы убедиться, что развертывание прошло успешно, выполните команду:

   ```sh
   kubectl -n longhorn-system get pod
   ```

   Результат должен выглядеть следующим образом:

   ```output
   NAME                                                READY   STATUS    RESTARTS   AGE
   csi-attacher-799967d9c-nx4f9                        1/1     Running   0          3m10s
   csi-attacher-799967d9c-vsz7g                        1/1     Running   0          3m10s
   csi-attacher-799967d9c-zh6vq                        1/1     Running   0          3m10s
   csi-provisioner-58f97759c-676jf                     1/1     Running   0          3m10s
   csi-provisioner-58f97759c-fxsb5                     1/1     Running   0          3m10s
   csi-provisioner-58f97759c-krfs2                     1/1     Running   0          3m10s
   csi-resizer-6c9b8598f4-dzxwp                        1/1     Running   0          3m10s
   csi-resizer-6c9b8598f4-kkfn4                        1/1     Running   0          3m10s
   csi-resizer-6c9b8598f4-wq47f                        1/1     Running   0          3m10s
   csi-snapshotter-5c5f9b754d-4pdbg                    1/1     Running   0          3m10s
   csi-snapshotter-5c5f9b754d-7n7wf                    1/1     Running   0          3m10s
   csi-snapshotter-5c5f9b754d-q4rzx                    1/1     Running   0          3m10s
   engine-image-ei-5cefaf2b-8j4j9                      1/1     Running   0          3m14s
   engine-image-ei-5cefaf2b-94g2f                      1/1     Running   0          3m14s
   engine-image-ei-5cefaf2b-g5bg5                      1/1     Running   0          3m14s
   instance-manager-3af1ba7167264c2020df4d36d77d3905   1/1     Running   0          3m14s
   instance-manager-8452580cb8e2bc9ad134bb6a1c2806cc   1/1     Running   0          3m12s
   instance-manager-a006e8fdef719ff0b5aee753abbe1dd8   1/1     Running   0          3m14s
   longhorn-csi-plugin-bswvc                           3/3     Running   0          3m10s
   longhorn-csi-plugin-fmlrd                           3/3     Running   0          3m10s
   longhorn-csi-plugin-tpnqm                           3/3     Running   0          3m10s
   longhorn-driver-deployer-68b5879955-7tkrs           1/1     Running   0          3m31s
   longhorn-manager-5psrc                              1/1     Running   0          3m31s
   longhorn-manager-5qjbd                              1/1     Running   0          3m31s
   longhorn-manager-rwzbb                              1/1     Running   0          3m31s
   longhorn-ui-9ccf5c989-bxdv2                         1/1     Running   0          3m31s
   longhorn-ui-9ccf5c989-dsvz6                         1/1     Running   0          3m31s
   ```

1. Чтобы включить доступ к пользовательскому интерфейсу Longhorn, необходимо настроить контроллер Ingress.

   По умолчанию аутентификация в пользовательском интерфейсе Longhorn не включена.
   Информацию о создании контроллера NGINX Ingress с базовой аутентификацией см. в [этом разделе](https://longhorn.io/docs/1.6.2/deploy/accessing-the-ui/longhorn-ingress).

1. Войдите в пользовательский интерфейс Longhorn, выполнив [следующие действия](https://longhorn.io/docs/1.6.2/deploy/accessing-the-ui).

Посмотреть на веб интерфейс можно так:

```sh
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80
```

## Ingress Controller

Ingress Controller - это компонент в Kubernetes, который управляет входящими HTTP и HTTPS запросами в кластер.
Он обеспечивает балансировку нагрузки, маршрутизацию трафика и обеспечивает доступ к службам внутри кластера извне.

Ingress Controller работает на уровне приложения и использует информацию из объекта Ingress, который определяет правила маршрутизации для входящего трафика.
Это позволяет настраивать маршрутизацию трафика без изменения конфигурации службы или приложения.

### Установка при помощи helm

Добавьте репозиторий Traefik Labs в Helm:

```sh
helm repo add traefik https://traefik.github.io/charts
```

Вы можете обновить хранилище, выполнив команду:

```sh
helm repo update
```

И установите его с помощью командной строки Helm:

```sh
helm upgrade \
  --install \
  --namespace traefik \
  --create-namespace \
  traefik traefik/traefik \
  --values traefik/values.yaml
```

```sh
helm upgrade \
  --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.kind=DaemonSet \
  --set controller.hostNetwork=false \
  --set controller.hostPort.enabled=false \
  --set controller.service.loadBalancerIP=10.0.70.199
```

### Проброс дашборда Traefik

```sh
kubectl port-forward -n traefik $(kubectl get pods -n traefik --selector "app.kubernetes.io/name=traefik" --output=name) 9000:9000
```

Его ним можно увидеть по адресу: [127.0.0.1:9000/dashboard/](http://127.0.0.1:9000/dashboard/)

## Удаляем узел из кластера

В Kubernetes, для удаления узла (node) из кластера, вы можете использовать следующую команду kubectl

```sh
kubectl get nodes -o wide
```

Эти команды выполняют следующие действия:

- kubectl drain - этот шаг убеждается, что все поды, которые могут быть перезапущены в другом месте, были перезапущены.
  Он также удаляет все пустые директории, которые были созданы подами на узле,
  и удаляет все поды, которые не могут быть перезапущены в другом месте (например, поды, которые имеют локальные данные).

```sh
kubectl drain kubeadm-node-01 --delete-local-data --force --ignore-daemonsets
```

- kubectl delete node - этот шаг удаляет узел из кластера.
  Обратите внимание, что эти команды могут привести к потере данных,
  поэтому убедитесь, что вы понимаете, что делаете, и что у вас есть резервное копирование данных, если это необходимо.

```sh
kubectl delete node kubeadm-node-01
```

## Просмотр списка join ссылок в Kubernetes

Для просмотра списка join ссылок в Kubernetes, вы можете использовать команду kubeadm token list.
Эта команда отобразит список всех активных join токенов, которые могут быть использованы для присоединения новых узлов к кластеру.

Вот пример использования:

```sh
kubeadm token list
```

Для получения join ссылки в Kubernetes, вы можете использовать команду kubeadm token create --print-join-command.
Эта команда создаст новый join токен и напечатает команду, которую вы можете использовать для присоединения новых узлов к кластеру.

Вот пример использования:

```sh
kubeadm token create --print-join-command
```
