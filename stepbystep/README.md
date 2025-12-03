# learn-devops

## Описание

В этом репозитории собраны примеры с [YouTube](https://www.youtube.com/@fedor_batonogov)/[Rutube](https://rutube.ru/channel/31656928) каналов.
Тут я рассказываю о разных инструментах необходимых для **DevOps специалиста** и делюсь опытом.

## Мы стремимся подходу **Инфраструктура как код**

Основная идея **Infrastructure as Code (IaC)** в том, чтобы **описать инфраструктуру кодом** и сделать её доступной для понимания.
IaC работает со всеми компонентами инфраструктуры так, будто это просто данные.
Такое стало возможно благодаря умению платформ виртуализации и облачных провайдеров разделять инфраструктуру и оборудование,
а для управления серверами, хранилищами и сетевыми устройствами предоставлять специальное API.

## Структура проекта

1. [Создание VM](./01istall-vm/) - это программная платформа для быстрой сборки, отладки и развертывания приложений с помощью **контейнеров**.
Проходим по реадми шаг за шагом

2. [Установка k8s](./02install-k8s-kluster/) - это инструменты для простого и быстрого развёртывания кластера Kubernetes.
Заходим в директорию [Ansible](stepbystep/02install-k8s-kluster/ansible/) — система управления конфигурациями, написанная на языке программирования **Python**,
с использованием **декларативного языка разметки** для **описания конфигураций**.
Применяется для **автоматизации настройки и развёртывания программного обеспечения**.

2.1 вариант Установка кластера без kubeProxy [README.md](02install-k8s-kluster/variant1/ansible/README.md) + CILIUM
(виртуальное окружение source /Users/admin/virtual-environments/ans_latest/bin/activate)
2.2 варианты с установкой кластера с различными CNI + HA [README.md](02install-k8s-kluster/variant2/00-kube-ansible/README.md)
(виртуальное окружение source /Users/admin/virtual-environments/ans_2_17_for_install_kluster_kaa/bin/activate)


## Шаг за шагом все команды на примере Debian 12 (с текущей директории)
Прописать IP в inventory и для opentofu
1. Развертывание тачек
```shell
cd stepbystep/01istall-vm/opentofu/kubeadm-deb-12
tofu validate
tofu plan
tofu apply (tofu destroy)
```
2. Установка кластера (с настроенным CNI = calico)
```shell
cd ../../../02install-k8s-kluster/variant2/00-kube-ansible/
source /Users/admin/virtual-environments/ans_2_17_for_install_kluster_kaa/bin/activate
ansible-playbook install-cluster.yaml --diff -u root
```