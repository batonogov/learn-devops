Настройка NTP
=========

Данная роль настраивает часовой пояс и NTP на узлах.

Requirements
------------

Тестирование приводилось на **Ubuntu 20.04 (Focal Fossa)** и **Ubuntu 22.04 (Jammy Jellyfish)**.

Role Variables
--------------

Переменные не используются.

Dependencies
------------

Для настройки часового пояса используется роль [community.general.timezone](https://docs.ansible.com/ansible/latest/collections/community/general/timezone_module.html), в качестве параметра принимается строка с нужным часовым поясом, например **Europe/Moscow**.

Example Playbook
----------------

    - hosts: servers
      roles:
        - ntp-install

License
-------

MIT

Author Information
------------------

Федор Батоногов f.batonogov@yandex.ru
