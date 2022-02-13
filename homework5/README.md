# mongo_otus

# ДЗ № 5

## В процессе сделано:

- Используем terraform и ansible для  развертывания отказоустойчивого кластера с двумя шардами;
- ввиду  ограничения триала  GCP до 8 ip адресов пожертвуем отказоустойчивостью config серверов;
- terraform создает 8 инстансов:
1) 1 config server;
2) 1 mongos server;
3) 2 шарда каждый с двумя репликами.
- Динамически создается inventory файл для ansible группируя хосты по принадлежности:
```
[mongo_cfg_instances]
34.124.248.59

[mongo_shard_instances]
34.126.183.61
34.124.208.75
34.124.171.98
34.124.156.77
34.124.213.222
35.247.189.244

[mongos_instances]
35.247.175.40
```
- Реплики находятся в разных зонах для отказоустойчивости:
```
gcloud compute instances list
NAME                ZONE               MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP     STATUS
mongodb-cfg0        asia-southeast1-a  e2-medium                  10.166.0.9   34.124.248.59   RUNNING
mongodb-shard0svr0  asia-southeast1-a  e2-medium                  10.166.0.8   34.126.183.61   RUNNING
mongodb-shard1svr0  asia-southeast1-a  e2-medium                  10.166.0.7   34.124.156.77   RUNNING
mongos0             asia-southeast1-a  e2-medium                  10.166.0.6   35.247.175.40   RUNNING
mongodb-shard0svr1  asia-southeast1-b  e2-medium                  10.166.0.4   34.124.208.75   RUNNING
mongodb-shard1svr1  asia-southeast1-b  e2-medium                  10.166.0.5   34.124.213.222  RUNNING
mongodb-shard0svr2  asia-southeast1-c  e2-medium                  10.166.0.2   34.124.171.98   RUNNING
mongodb-shard1svr2  asia-southeast1-c  e2-medium                  10.166.0.3   35.247.189.244  RUNNING
```
Устанавливаем соотвествующие роли на каждый сервер, используя переменные для создания шардов и реплик,везде включаем аутентификацию и systemd,прописываем ключи ssl между репликами:
- общий playbook  на установку базового по на все хосты:
```
ansible-playbook -i instances_mongodb/ansible/ansible_hosts.cfg ansible/playbook.yml
```
- установка конфиг сервера:
```
ansible-playbook -i /instances_mongodb/ansible/ansible_hosts.cfg playbook_cfg.yml
```
Так как конфиг сервер у нас один - проинизиализируем одну реплику :
```
rs.initiate()
cfg:PRIMARY> rs.status()
{
"members" : [
		{
			"_id" : 0,
			"name" : "mongodb-cfg0:27019",
			"health" : 1,
			"state" : 1,
			"stateStr" : "PRIMARY",
			"uptime" : 1994,
			"optime" : {
				"ts" : Timestamp(1644747358, 1),
				"t" : NumberLong(2)

		
	],
	"ok" : 1,
...
}
```
- Установка mongos
```
ansible-playbook -i instances_mongodb/ansible/ansible_hosts.cfg ansible/playbook_mongos.yml
cat playbook_mongos.yml
---
- hosts: mongos_instances
  remote_user: ubuntu
  become: yes 
  vars:
    config_repl_set_name: cfg
    config_servers: "34.124.248.59:27019"
  roles:
    - mongodb_mongos
```
- Установка первого шардированного кластера
```
ansible-playbook -i instances_mongodb/ansible/ansible_hosts.cfg -l 34.126.183.61, 34.124.208.75, 34.124.171.98  ansible/playbook_shard0.yml
cat ansible/playbook_shard0.yml
---
- hosts: mongo_shard_instances
  remote_user: ubuntu
  become: yes 
  vars:
    repl_set_name: shard0
    sharding: true


  roles:
    - mongodb_mongod
```
Создадим репликасет:
```
rs.initiate(
  {
    _id : "shard0",
    members: [
      { _id : 0, host : "mongodb-shard0svr0:27017" },
      { _id : 1, host : "mongodb-shard0svr1:27017" },
      { _id : 2, host : "mongodb-shard0svr2:27017" }
    ]
  }
)

rs.status()
shard0:PRIMARY> rs.status()
{

	"set" : "shard0",
	
	...
		"priorityAtElection" : 1,
		"electionTimeoutMillis" : NumberLong(10000),
		"numCatchUpOps" : NumberLong(0),
		"newTermStartDate" : ISODate("2022-02-13T10:49:35.660Z"),
		"wMajorityWriteAvailabilityDate" : ISODate("2022-02-13T10:49:36.753Z")
	},
	"members" : [
		{
			"_id" : 0,
			"name" : "mongodb-shard0svr0:27017",
			"health" : 1,
			"state" : 1,
			"stateStr" : "PRIMARY",
			"uptime" : 472,
...
		},
		{
			"_id" : 1,
			"name" : "mongodb-shard0svr1:27017",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 33,
			"optime" : {
				"ts" : Timestamp(1644749395, 1),
				"t" : NumberLong(1)
			},
			"optimeDurable" : {
				"ts" : Timestamp(1644749395, 1),
				"t" : NumberLong(1)
			},
...
		},
		{
			"_id" : 2,
			"name" : "mongodb-shard0svr2:27017",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 33,
			"optime" : {
				"ts" : Timestamp(1644749395, 1),
				"t" : NumberLong(1)
			},
	
		}
	],
	"ok" : 1
}
```

- Установка второго шардированного кластера
```
ansible-playbook -i instances_mongodb/ansible/ansible_hosts.cfg -l 34.124.156.77, 34.124.213.222, 35.247.189.244  ansible/playbook_shard1.yml

cat playbook_shard1.yml
---
- hosts: mongo_shard_instances
  remote_user: ubuntu
  become: yes 
  vars:
    repl_set_name: shard1
    sharding: true
  
  roles:
    - mongodb_mongod
```
Создадим репликасет:
```
rs.initiate(
  {
    _id : "shard1",
    members: [
      { _id : 0, host : "mongodb-shard1svr0:27017" },
      { _id : 1, host : "mongodb-shard1svr1:27017" },
      { _id : 2, host : "mongodb-shard1svr2:27017" }
    ]
  }
)
rs.status()
shard1:PRIMARY> rs.status()
{
	"set" : "shard1",
	"date" : ISODate("2022-02-13T11:06:44.016Z"),
	"myState" : 1,
	"term" : NumberLong(1),
	"syncSourceHost" : "",
	"syncSourceId" : -1,
	"heartbeatIntervalMillis" : NumberLong(2000),
...
	},
	"members" : [
		{
			"_id" : 0,
			"name" : "mongodb-shard1svr0:27017",
			"health" : 1,
			"state" : 1,
			"stateStr" : "PRIMARY",
			"uptime" : 91,
			"optime" : {
				"ts" : Timestamp(1644750401, 5),
				"t" : NumberLong(1)
			},
...
		},
		{
			"_id" : 1,
			"name" : "mongodb-shard1svr1:27017",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 12,
...
		},
		{
			"_id" : 2,
			"name" : "mongodb-shard1svr2:27017",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 12,
			"optime" : {
				"ts" : Timestamp(1644750401, 5),
...
		}
	],
	"ok" : 1
}
```
- Соберем шардированный кластер :
```
sh.addShard( "shard0/mongodb-shard0svr0:27017,mongodb-shard0svr1:27017,mongodb-shard0svr2:27017")


{
	"shardAdded" : "shard0",
	"ok" : 1,
	"operationTime" : Timestamp(1644751236, 3),
	"$clusterTime" : {
		"clusterTime" : Timestamp(1644751236, 3),
		"signature" : {
			"hash" : BinData(0,"QXCxRcH5K2RYJebXWRnjXIRvj74="),
			"keyId" : NumberLong("7061867953448288279")
		}
	}
sh.addShard( "shard1/mongodb-shard1svr0:27017,mongodb-shard1svr1:27017,mongodb-shard1svr2:27017")

{
	"shardAdded" : "shard1",
	"ok" : 1,
	"operationTime" : Timestamp(1644751336, 5),
	"$clusterTime" : {
		"clusterTime" : Timestamp(1644751336, 5),
		"signature" : {
			"hash" : BinData(0,"cgmC5qO4l7wbNujAu+ams0GaDWM="),
			"keyId" : NumberLong("7061867953448288279")
		}
	}
}
sh.status()
--- Sharding Status ---
  sharding version: {
  	"_id" : 1,
  	"minCompatibleVersion" : 5,
  	"currentVersion" : 6,
  	"clusterId" : ObjectId("6200cb7d671df4be8ee76240")
  }
  shards:
        {  "_id" : "shard0",  "host" : "shard0/mongodb-shard0svr0:27017,mongodb-shard0svr1:27017,mongodb-shard0svr2:27017",  "state" : 1 }
        {  "_id" : "shard1",  "host" : "shard1/mongodb-shard1svr0:27017,mongodb-shard1svr1:27017,mongodb-shard1svr2:27017",  "state" : 1 }
  active mongoses:
        "4.4.12" : 1
  autosplit:
        Currently enabled: yes
  balancer:
        Currently enabled:  yes
        Currently running:  no
        Failed balancer rounds in last 5 attempts:  0
        Migration Results for the last 24 hours:
                15 : Success
```
- Загрузим базу и создадим индекс на поле с высокой координальностью(в данном случае хорошим кандидатом будет уникальное имя компании,учавствующей на бирже) :
```
 mongorestore dump --port 27017 -u mongo -p password
2022-02-13T11:27:06.215+0000	WARNING: On some systems, a password provided directly using --password may be visible to system status programs such as `ps` that may be invoked by other users. Consider omitting the password to provide it via stdin, or using the --config option to specify a configuration file with the password.
2022-02-13T11:27:06.232+0000	preparing collections to restore from
2022-02-13T11:27:06.233+0000	no metadata; falling back to system.indexes
2022-02-13T11:27:06.334+0000	restoring stocks.values from dump/stocks/values.bson
2022-02-13T11:27:09.232+0000	[........................]  stocks.values  13.9MB/715MB  (2.0%)
2022-02-13T11:27:12.232+0000	[........................]  stocks.values  28.4MB/715MB  (4.0%)
2022-02-13T11:27:15.231+0000	[#.......................]  stocks.values  42.8MB/715MB  (6.0%)
2022-02-13T11:27:18.231+0000	[#.......................]  stocks.v
...
2022-02-13T11:29:42.360+0000	[########################]  stocks.values  715MB/715MB  (100.0%)
2022-02-13T11:29:42.360+0000	finished restoring stocks.values (4308303 documents, 0 failures)
2022-02-13T11:29:42.360+0000	no indexes to restore for collection stocks.values
2022-02-13T11:29:42.360+0000	4308303 document(s) restored successfully. 0 document(s) failed to restore.

db.values.createIndex({stock_symbol: 1})
{
	"raw" : {
		"shard1/mongodb-shard1svr0:27017,mongodb-shard1svr1:27017,mongodb-shard1svr2:27017" : {
			"createdCollectionAutomatically" : false,
			"numIndexesBefore" : 1,
			"numIndexesAfter" : 2,
			"commitQuorum" : "votingMembers",
			"ok" : 1
		}
	},
	"ok" : 1,

- Шаридруем базу:
sh.enableSharding("stocks")
{
	"ok" : 1,

 sh.shardCollection("stocks.values",{ stock_symbol: 1 })
--- Sharding Status ---
  sharding version: {
  	"_id" : 1,
  	"minCompatibleVersion" : 5,
  	"currentVersion" : 6,
  	"clusterId" : ObjectId("6200cb7d671df4be8ee76240")
  }
  shards:
        {  "_id" : "shard0",  "host" : "shard0/mongodb-shard0svr0:27017,mongodb-shard0svr1:27017,mongodb-shard0svr2:27017",  "state" : 1 }
        {  "_id" : "shard1",  "host" :"shard1/mongodb-shard1svr0:27017,mongodb-shard1svr1:27017,mongodb-shard1svr2:27017",  "state" : 1 }
  active mongoses:
        "4.4.12" : 1
  autosplit:
        Currently enabled: yes
  balancer:
        Currently enabled:  yes
        Currently running:  no
        Failed balancer rounds in last 5 attempts:  0
        Migration Results for the last 24 hours:
                517 : Success
  databases:
        {  "_id" : "<database>",  "primary" : "shard0",  "partitioned" : true,  "version" : {  "uuid" : UUID("4fbfa19a-5613-4dc3-aa40-f48d5cea3a9b"),  "lastMod" : 1 } }
        {  "_id" : "config",  "primary" : "config",  "partitioned" : true }
                config.system.sessions
                        shard key: { "_id" : 1 }
                        unique: false
                        balancing: true
                        chunks:
                                shard0	512
                                shard1	512
                        too many chunks to print, use verbose if you want to force print
        {  "_id" : "stocks",  "primary" : "shard1",  "partitioned" : true,  "version" : {  "uuid" : UUID("23ed6333-18e6-4742-9dc3-1f541556722f"),  "lastMod" : 1 } }
                stocks.values
                        shard key: { "stock_symbol" : 1 }
                        unique: false
                        balancing: true
                        chunks:
                                shard0	5
                                shard1	6
                        { "stock_symbol" : { "$minKey" : 1 } } -->> { "stock_symbol" : "AMIC" } on : shard0 Timestamp(2, 0)
                        { "stock_symbol" : "AMIC" } -->> { "stock_symbol" : "ATRO" } on : shard0 Timestamp(3, 0)
                        { "stock_symbol" : "ATRO" } -->> { "stock_symbol" : "BKUNA" } on : shard0 Timestamp(4, 0)
                        { "stock_symbol" : "BKUNA" } -->> { "stock_symbol" : "CALM" } on : shard0 Timestamp(5, 0)
                        { "stock_symbol" : "CALM" } -->> { "stock_symbol" : "CNIC" } on : shard0 Timestamp(6, 0)
                        { "stock_symbol" : "CNIC" } -->> { "stock_symbol" : "DAGM" } on : shard1 Timestamp(6, 1)
                        { "stock_symbol" : "DAGM" } -->> { "stock_symbol" : "ENDO" } on : shard1 Timestamp(1, 6)
                        { "stock_symbol" : "ENDO" } -->> { "stock_symbol" : "FMBI" } on : shard1 Timestamp(1, 7)
                        { "stock_symbol" : "FMBI" } -->> { "stock_symbol" : "MACE" } on : shard1 Timestamp(1, 8)
                        { "stock_symbol" : "MACE" } -->> { "stock_symbol" : "MTCT" } on : shard1 Timestamp(1, 9)
                        { "stock_symbol" : "MTCT" } -->> { "stock_symbol" : { "$maxKey" : 1 } } on : shard1 Timestamp(1, 10)
```
