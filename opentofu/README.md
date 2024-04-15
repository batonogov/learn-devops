# **Infrastructure as Code** и системы управления конфигурацией

Для развёртывания инфраструктуры согласно подходу **Infrastructure as Code**, используя **OpenTofu/Terraform** и создания необходимых ресурсов необходимо выполнить следующие шаги.

---

Официальный сайт проекта [OpenTofu](https://opentofu.org/).
Репозиторий провайдера [bpg/terraform-provider-proxmox](https://github.com/bpg/terraform-provider-proxmox).

---

## Подготовка Proxmox

### Создание шаблона Ubuntu 22.04

На узле Promox создаем шаблон **Cloud Init** **Ubuntu 22.04**

```sh
export PROXMOX_STORAGE=proxmox-data-01
apt update && apt install libguestfs-tools -y && \
wget --backups=1 https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img && \
virt-customize -a jammy-server-cloudimg-amd64.img --install qemu-guest-agent && \
qm create 9000 --name "ubuntu-22.04-cloudinit-template" --cores 2 --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci && \
qm set 9000 --virtio0 ${PROXMOX_STORAGE}:0,import-from=/root/jammy-server-cloudimg-amd64.img && \
qm set 9000 --ide2 ${PROXMOX_STORAGE}:cloudinit && \
qm set 9000 --boot order=virtio0 && \
qm set 9000 --serial0 socket --vga serial0 && \
qm template 9000
```

---

## Последовательность действий при работе с OpenTofu

### Инициализируем рабочий каталог, содержащий файлы конфигурации OpenTofu/Terraform

Команда **tofu init** инициализирует рабочий каталог, содержащий файлы конфигурации **OpenTofu**. Это первая команда, которую следует выполнить после записи новой конфигурации **OpenTofu** или клонирования существующей из системы управления версиями. Эту команду безопасно запускать несколько раз.

```bash
tofu init
```

### Проверяем файлы конфигурации в каталоге

Команда **tofu validate** проверяет файлы конфигурации в каталоге, ссылаясь только на конфигурацию и не обращаясь к каким-либо удаленным службам, таким как удаленное состояние, API-интерфейсы провайдеров и т.д.

```bash
tofu validate
```

### Создаем план

Команда **tofu plan** позволяет предварительно просмотреть действия, которые **OpenTofu** предпримет для изменения вашей инфраструктуры, или сохранить предполагаемый план, который вы сможете применить позже.

```bash
tofu plan
```

### Выполняем изменения, определенные конфигурацией **OpenTofu**

Команда **tofu apply** является более распространенным рабочим процессом вне автоматизации. Если вы не передадите сохраненный план команде применения, она выполнит все функции плана и предложит вам утвердить его перед внесением изменений.

```bash
tofu apply
```

### Удаляем ресурсы

Команда **tofu destroy** создает план выполнения для удаления всех ресурсов, управляемых в этом проекте.

```bash
tofu destroy
```

---

## Как задавать переменные

Значения переменных можно задать несколькими способами:

1. Через файл с расширением **.tfvars** (пачками)

```bash
instance_zone=ru-central-b
```

По умолчанию загружаем значения из **terraform.tfvars**, но можно явно обозначить файл для загрузки:

```bash
tofu apply -var-file="testing.tfvars"
```

2. Через переменные окружения. Переменная должна начинаться с **TF*VAR***, а дальше уже имя переменной

### Для простого типа

```bash
export TF_VAR_instance_zone=ru-central-d
```

### Для составного типа

```bash
export TF_VAR_instance_zone='["ru-central-a","ru-central-b"]'
```
