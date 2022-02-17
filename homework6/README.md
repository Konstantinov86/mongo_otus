# mongo_otus

# ДЗ № 6

## В процессе сделано:

Данное дз будет использоваться для проекта - "Построение сайта системы бронирования кинотеатра в kubernetes на go и mongo"
- Используем terraform для развертывния 3-х нодного EKS;
```
kubectl get nodes 
NAME                                                  STATUS   ROLES    AGE    VERSION
gke-otus-mongodb-otus-mongodb-node-po-a64529c4-j9xg   Ready    <none>   107s   v1.21.9-gke.300
gke-otus-mongodb-otus-mongodb-node-po-a64529c4-v177   Ready    <none>   106s   v1.21.9-gke.300
gke-otus-mongodb-otus-mongodb-node-po-a64529c4-x23w   Ready    <none>   107s   v1.21.9-gke.300
```
- Установим сервисы:

1)отказоустойчивый ingress-nginx для входящего трафика будущего сайта;

2)cert-manager для ssl сертификатов;

3)prometheus stack для мониторинга;

4)mongodb из 3х нод с affninity на разные ноды для отказоустойчивости,а также дополнительным sidecar container ,который отслеживает какая нода primary и сервисом с внешним пробросом по nodeport ,который подключается к primary node ;
```
helm/helmfile apply

kubectl get pods -o wide -n mongo
NAME        READY   STATUS    RESTARTS   AGE   IP            NODE                                                  NOMINATED NODE   READINESS GATES
mongodb-0   3/3     Running   0          55m   10.116.2.20   gke-otus-mongodb-otus-mongodb-node-po-a64529c4-x23w   <none>           <none>
mongodb-1   3/3     Running   0          54m   10.116.0.20   gke-otus-mongodb-otus-mongodb-node-po-a64529c4-j9xg   <none>           <none>
mongodb-2   3/3     Running   0          54m   10.116.1.19   gke-otus-mongodb-otus-mongodb-node-po-a64529c4-v177   <none>           <none>
```
- Создадим ингресс правила для grafana :
```
export nginx_ingress_ip=$(kubectl get svc --namespace=ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
#apply it to ingress prometheus
cat prometheus/ingress-grafana.yaml | sed "s/{{nginx_ingress_ip}}/$nginx_ingress_ip/g" | kubectl apply -f -
```
- Откроем внешний порт для mongo:
```
kubectl get svc | grep primary
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)           AGE
mongodb-primary    NodePort    10.120.2.29    <none>        30001:30001/TCP   4h14m

gcloud compute firewall-rules create mongo --allow tcp:30001
```
- Загрузим коллекции :
```
kubectl cp backup mongodb-0:/tmp/
kubectl exec -it mongodb-0 -- mongorestore --uri mongodb://localhost:27017  -u mongo -p password --gzip  /tmp/backup/cinema
```
- Проверим что все залилось и внешнее подключение:
```
mongo 34.88.214.209:30001/admin -u mongo -p password
MongoDB shell version v5.0.6
connecting to: mongodb://34.88.214.209:30001/admin?compressors=disabled&gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("746da262-4a1e-4e03-acf5-6c254a6d11fa") }
MongoDB server version: 4.4.12
WARNING: shell and server versions do not match

rs0:PRIMARY> show dbs;
admin      0.000GB
bookings   0.000GB
config     0.000GB
local      0.001GB
movies     0.000GB
showtimes  0.000GB
users      0.000GB
```


- Протестируем отказоустойчивость:
```
rs.status()
{
  set: 'rs0',
  date: 2022-02-17T11:14:59.705Z,
  myState: 1,
  term: Long("2"),
  syncSourceHost: '',
  syncSourceId: -1,
  heartbeatIntervalMillis: Long("2000"),
  majorityVoteCount: 2,
  writeMajorityCount: 2,
  votingMembersCount: 3,
  ...

  },
  members: [
    {
      _id: 0,
      name: 'mongodb-0.mongodb-headless.mongo.svc.cluster.local:27017',
      health: 1,
      state: 1,
      stateStr: 'PRIMARY',

    },
    {
      _id: 1,
      name: 'mongodb-1.mongodb-headless.mongo.svc.cluster.local:27017',
      health: 1,
      state: 2,
      stateStr: 'SECONDARY',
...

    },
    {
      _id: 2,
      name: 'mongodb-2.mongodb-headless.mongo.svc.cluster.local:27017',
      health: 1,
      state: 2,
      stateStr: 'SECONDARY',
...
  ],
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1645096497, i: 1 }),
    signature: {
      hash: Binary(Buffer.from("0c85da95e20f30b3040b9fdc9d9312f0c1830697", "hex"), 0),
      keyId: Long("7065619963863629829")
    }
  },
  operationTime: Timestamp({ t: 1645096497, i: 1 })
}

```
- Посмотрим на какой ноде находится primary и остановим ее:
```
NAME        READY   STATUS    RESTARTS   AGE    IP            NODE                                                  NOMINATED NODE   READINESS GATES
mongodb-0   3/3     Running   0          17s    10.116.1.29   gke-otus-mongodb-otus-mongodb-node-po-a64529c4-v177   <none>           <none>
mongodb-1   3/3     Running   0          51s    10.116.0.25   gke-otus-mongodb-otus-mongodb-node-po-a64529c4-j9xg   <none>           <none>
mongodb-2   3/3     Running   0          101s   10.116.2.27   gke-otus-mongodb-otus-mongodb-node-po-a64529c4-x23w   <none>           <none>

kubectl drain gke-otus-mongodb-otus-mongodb-node-po-a64529c4-v177  --ignore-daemonsets --force --delete-emptydir-data

evicting pod mongo/mongodb-0

kubectl get pods
NAME        READY   STATUS    RESTARTS   AGE
mongodb-0   0/3     Pending   0          21s
mongodb-1   3/3     Running   0          3m1s
mongodb-2   3/3     Running   0          3m51s
```
- Пробуем подключиться:
```
mongo 34.88.214.209:30001/admin -u mongo -p password

rs0:PRIMARY> rs.status()
{
	"set" : "rs0",
	"date" : ISODate("2022-02-17T15:04:52.265Z"),
	"myState" : 1,
	"term" : NumberLong(15),
	"syncSourceHost" : "",
	"syncSourceId" : -1,
	"heartbeatIntervalMillis" : NumberLong(2000),
	"majorityVoteCount" : 2,
	"writeMajorityCount" : 2,
	"votingMembersCount" : 3,
	"writableVotingMembersCount" : 3,
	"optimes" : {
		"lastCommittedOpTime" : {
			"ts" : Timestamp(1645110283, 1),
			"t" : NumberLong(15)
		},
		"lastCommittedWallTime" : ISODate("2022-02-17T15:04:43.254Z"),
		"readConcernMajorityOpTime" : {
			"ts" : Timestamp(1645110283, 1),
			"t" : NumberLong(15)
		},
		"readConcernMajorityWallTime" : ISODate("2022-02-17T15:04:43.254Z"),
		"appliedOpTime" : {
			"ts" : Timestamp(1645110283, 1),
			"t" : NumberLong(15)
		},

	"members" : [
		{
			"_id" : 0,
			"name" : "mongodb-0.mongodb-headless.mongo.svc.cluster.local:27017",
			"health" : 0,
			"state" : 8,
			"stateStr" : "(not reachable/healthy)",
			"uptime" : 0,
			"optime" : {
				"ts" : Timestamp(0, 0),
				"t" : NumberLong(-1)
			},
			"optimeDurable" : {
				"ts" : Timestamp(0, 0),
				"t" : NumberLong(-1)
			},
			"optimeDate" : ISODate("1970-01-01T00:00:00Z"),
			"optimeDurableDate" : ISODate("1970-01-01T00:00:00Z"),
			"lastAppliedWallTime" : ISODate("2022-02-17T15:03:41.572Z"),
			"lastDurableWallTime" : ISODate("2022-02-17T15:03:41.572Z"),
			"lastHeartbeat" : ISODate("2022-02-17T15:04:52.190Z"),
			"lastHeartbeatRecv" : ISODate("2022-02-17T15:03:43.768Z"),
			"pingMs" : NumberLong(0),
			"lastHeartbeatMessage" : "Error connecting to mongodb-0.mongodb-headless.mongo.svc.cluster.local:27017 :: caused by :: Could not find address for mongodb-0.mongodb-headless.mongo.svc.cluster.local:27017: SocketException: Host not found (authoritative)",
			"syncSourceHost" : "",
			"syncSourceId" : -1,
			"infoMessage" : "",
			"configVersion" : 7,
			"configTerm" : 14
		},
		{
			"_id" : 1,
			"name" : "mongodb-1.mongodb-headless.mongo.svc.cluster.local:27017",
			"health" : 1,
			"state" : 1,
			"stateStr" : "PRIMARY",
			"uptime" : 205,
			"optime" : {
				"ts" : Timestamp(1645110283, 1),
				"t" : NumberLong(15)
			},
			"optimeDate" : ISODate("2022-02-17T15:04:43Z"),
			"lastAppliedWallTime" : ISODate("2022-02-17T15:04:43.254Z"),
			"lastDurableWallTime" : ISODate("2022-02-17T15:04:43.254Z"),
			"syncSourceHost" : "",
			"syncSourceId" : -1,
			"infoMessage" : "",
			"electionTime" : Timestamp(1645110223, 1),
			"electionDate" : ISODate("2022-02-17T15:03:43Z"),
			"configVersion" : 7,
			"configTerm" : 15,
			"self" : true,
			"lastHeartbeatMessage" : ""
		},
		{
			"_id" : 2,
			"name" : "mongodb-2.mongodb-headless.mongo.svc.cluster.local:27017",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 203,
			"optime" : {
				"ts" : Timestamp(1645110283, 1),
				"t" : NumberLong(15)
			},
			"optimeDurable" : {
				"ts" : Timestamp(1645110283, 1),
				"t" : NumberLong(15)

	"operationTime" : Timestamp(1645110283, 1)
}

```
- Как мы видим кластер доступен и primary node переехала на 2-ю ноду,также отработал наш sidecar container переключив сервис подключения на вторую ноду