# **Infrastructure as Code** и системы управления конфигурацией

Для развёртывания инфраструктуры согласно подходу **Infrastructure as Code**, используя **OpenTofu/Terraform** и создания необходимых ресурсов необходимо выполнить следующие шаги.

---

## Что такое OpenTofu/Terraform

**Terraform** — это инструмент для создания и управления инфраструктурой.
С его помощью можно создавать, обновлять и удалять любые интересующие вас ресурсы в различных облачных и не только облачных сервисах.

**Terraform** позволяет описывать инфраструктуру в виде кода, что делает процесс её создания более эффективным и управляемым.
Код на языке **HCL** (HashiCorp Configuration Language) описывает требуемую инфраструктуру, а **Terraform** автоматически создаёт или обновляет её.

Информация об **OpenTofu** взята с [habr.com](https://habr.com/ru/companies/flant/news/762356/).

20 сентября, на сайте **Linux Foundation** появилась новость о том, что фонд принял **OpenTofu** в число своих проектов.
Теперь свободный форк **Terraform** будет развиваться под управлением **Linux Foundation**, что дает ряд преимуществ:

- Он будет всегда **Open Source** — то есть соответствовать **Open Source Definition**, а не размытому определению «открытые исходники».
- Он будет управляться открытым сообществом, а значит, прозрачно реализовывать и отражать видение разных разработчиков, а не единственного вендора.
- Он будет беспристрастным — то есть не зависящим от прихотей одной компании.

Кроме того, сами создатели открытого форка **Terraform** отмечают еще две особенности, которые повлечет за собой принятие проекта в **Linux Foundation**:
обратная совместимость и хорошо проработанная модульная архитектура.

Официальный сайт проекта [OpenTofu](https://opentofu.org/).
Репозиторий провайдера [bpg/terraform-provider-proxmox](https://github.com/bpg/terraform-provider-proxmox).

---

## Подготовка Proxmox

### Создание шаблона Ubuntu 22.04

На узле Proxmox создаем шаблон **Cloud Init** **Ubuntu 22.04**

```sh
export PROXMOX_STORAGE=local-lvm
apt update && apt install libguestfs-tools -y && \
wget --backups=1 https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img && \
virt-customize -a jammy-server-cloudimg-amd64.img --install qemu-guest-agent && \
qm create 2204 --name "ubuntu-22.04-cloudinit-template" --cores 2 --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci && \
qm set 2204 --virtio0 ${PROXMOX_STORAGE}:0,import-from=/root/jammy-server-cloudimg-amd64.img && \
qm set 2204 --ide2 ${PROXMOX_STORAGE}:cloudinit && \
qm set 2204 --boot order=virtio0 && \
qm set 2204 --serial0 socket --vga serial0 && \
qm template 2204
```
wget --backups=1 https://download.rockylinux.org/pub/rocky/9.6/BaseOS/x86_64/os/images/install.img && \


Шаблон Rocky Linux 9
```sh
export PROXMOX_STORAGE=local-lvm
apt update && apt install libguestfs-tools -y && \
virt-customize -a Rocky-9-GenericCloud-Base-9.4-20240509.0.x86_64.qcow2 --install qemu-guest-agent && \
qm create 960 --name "rockylinux-9.6-cloudinit-template" --cores 2 --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci && \
qm set 960 --virtio0 ${PROXMOX_STORAGE}:0,import-from=/var/lib/vz/template/qcow2/Rocky-9-GenericCloud-Base-9.4-20240509.0.x86_64.qcow2 && \
qm set 960 --ide2 ${PROXMOX_STORAGE}:cloudinit && \
qm set 960 --boot order=virtio0 && \
qm set 960 --serial0 socket --vga serial0 && \
qm template 960
```
Вторая версия (ок)
```sh
export PROXMOX_STORAGE=local-lvm
export VMID=9009

apt update && apt install libguestfs-tools -y && \
wget --backups=1 https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2 -O rocky9.qcow2 && \
virt-customize -a rocky9.qcow2 --install qemu-guest-agent && \
qm create $VMID --name "rocky-9-cloudinit-template" --cores 2 --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci && \
qm set $VMID --virtio0 ${PROXMOX_STORAGE}:0,import-from=/root/rocky9.qcow2 && \
qm set $VMID --ide2 ${PROXMOX_STORAGE}:cloudinit && \
qm set $VMID --boot order=virtio0 && \
qm set $VMID --serial0 socket --vga serial0 && \
qm template $VMID
```

Шаблон Debian 12 (Bookworm)
```sh
export PROXMOX_STORAGE=local-lvm
export VMID=9012

apt update && apt install libguestfs-tools -y && \
wget --backups=1 https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2 -O debian12.qcow2 && \
virt-customize -a debian12.qcow2 --install qemu-guest-agent && \
qm create $VMID --name "debian-12-cloudinit-template" --cores 2 --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci && \
qm set $VMID --virtio0 ${PROXMOX_STORAGE}:0,import-from=/root/debian12.qcow2 && \
qm set $VMID --ide2 ${PROXMOX_STORAGE}:cloudinit && \
qm set $VMID --boot order=virtio0 && \
qm set $VMID --serial0 socket --vga serial0 && \
qm template $VMID
```

---

## Последовательность действий при работе с OpenTofu

### Инициализируем рабочий каталог, содержащий файлы конфигурации OpenTofu/Terraform

Команда **tofu init** инициализирует рабочий каталог, содержащий файлы конфигурации **OpenTofu**. Это первая команда, которую следует выполнить после записи новой конфигурации **OpenTofu** или клонирования существующей из системы управления версиями. Эту команду безопасно запускать несколько раз.

```bash
tofu init
```
Если не работает в России
```shell
cat << 'EOF' >> ~/.tofurc
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.opentofu.org/*/*"]
  }
  direct {
    exclude = ["registry.opentofu.org/*/*"]
  }
}
EOF
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
