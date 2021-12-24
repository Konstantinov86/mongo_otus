# mongo_otus

# ДЗ № 2

## В процессе сделано:

- Создан  проект в  gcloud - otus-mongodb;
- созданы манифесты terraform  для развертывания:
1) создание инстанса с заданными параметрами;
2) создание своей  сети и  подсети в регионе  europe-north1;
3) проброс ключа ssh;
4) создание правило farewall для открытия 22 и 27019  портов для  сети;
5) используется backend terraform cloud  для хранения переменных и ключей;


- Используется ansible для настройки хоста и развертывания инстанса mongodb и запуска службы,используя public ip(ключ у нас проброшен):
1) Настройка  os и лимитов;
2) поключение репозитория mongodb;
3) установка пакетов;
4) настройка selinux;
5) проверка директорий,копирование  конфига из шаблона,запуск службы.Настроен отличный от умолчательного порт - 27019,включенная авторизация;


playbook.yml:
```
---
- hosts: all
  remote_user: ubuntu
  become: yes 

  roles:
    - mongodb_linux
    - mongodb_repository
    - mongodb_install
    - mongodb_selinux
    - mongodb_config
```
```
ansible-playbook -u  ubuntu -i 34.88.119.242, playbook.yml
```

- зайдем на сервер и создадим свою бд :
```
ssh ubuntu@34.88.119.242
mongo --port 27019
use mongotest
db.createCollection("movies")
> show dbs
admin      0.000GB
config     0.000GB
local      0.000GB
mongotest  0.000GB
```
- Создадим пользователя и подключимся удаленно: 
```
use admin;
db.createUser( { user: "mongo", pwd: "password", roles: [ "userAdminAnyDatabase", "dbAdminAnyDatabase", "readWriteAnyDatabase" ] } )
````
```
mongo 34.88.119.242:27019 -u mongo -p password --authenticationDatabase admin
MongoDB shell version v4.4.10
connecting to: mongodb://34.88.119.242:27019/test?authSource=admin&compressors=disabled&gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("c62e998d-a3a7-4567-b894-6a60a24ad04f") }
MongoDB server version: 4.4.10
```
