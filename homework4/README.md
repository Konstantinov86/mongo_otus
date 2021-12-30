# mongo_otus

# ДЗ № 4

## В процессе сделано:

- Используем terraform и ansible из дз2 для развертывания инстанса mongo;
- Скачиваем dataset  stocks  и  развертываем в инстансе c помощью mongorestore:

- Включим профилирование  :
```
> db.setProfilingLevel(2)
{ "was" : 0, "slowms" : 100, "sampleRate" : 1, "ok" : 1 }
> db.getProfilingStatus()
{ "was" : 2, "slowms" : 100, "sampleRate" : 1 }
```
- Сдалаем запрос на выборку по дате:
```
db.values.find({"date" : "2006-04-10" } )
```
и посмотрим профайлер :
```
	"responseLength" : 18077,
	"protocol" : "op_msg",
	"millis" : 129,
	"planSummary" : "COLLSCAN",
	"execStats" : {
		"stage" : "COLLSCAN",
		"filter" : {
			"date" : {
				"$eq" : "2006-04-10"
			}
		},
		"nReturned" : 101,
		"executionTimeMillisEstimate" : 11,
		"works" : 284740,
		"advanced" : 101,
		"needTime" : 284639,
		"needYield" : 0,
		"saveState" : 285,
		"restoreState" : 284,
		"isEOF" : 0,
		"direction" : "forward",
		"docsExamined" : 284739
	},
	"ts" : ISODate("2021-12-30T06:41:23.827Z"),
	"client" : "127.0.0.1",
	"appName" : "MongoDB Shell",
	"allUsers" : [
		{
			"user" : "mongo",
			"db" : "admin"
		}
	],
	"user" : "mongo@admin"
   ```
   Создадим индекс на дату:
   ```
   db.values.createIndex({date : 1})
{
	"createdCollectionAutomatically" : false,
	"numIndexesBefore" : 1,
	"numIndexesAfter" : 2,
	"ok" : 1
```
 Сделаем explain запроса и проверим что работатет по индексу поиск :

```
db.values.explain().find({"date" : "2006-04-10" } )
{
	"queryPlanner" : {
		"plannerVersion" : 1,
		"namespace" : "stocks.values",
		"indexFilterSet" : false,
		"parsedQuery" : {
			"date" : {
				"$eq" : "2006-04-10"
			}
		},
		"queryHash" : "0FB5AAC4",
		"planCacheKey" : "3A9F8749",
		"winningPlan" : {
			"stage" : "FETCH",
			"inputStage" : {
				"stage" : "IXSCAN",
				"keyPattern" : {
					"date" : 1
				},
				"indexName" : "date_1",
				"isMultiKey" : false,
				"multiKeyPaths" : {
					"date" : [ ]
				},

				}
			}
		},
		"rejectedPlans" : [ ]
```
и Посмотрим в profiler  анализ запроса по  дате :
```
"responseLength" : 18077,
	"protocol" : "op_msg",
	"millis" : 0,
	"planSummary" : "IXSCAN { date: 1 }",
	"execStats" : {
		"stage" : "FETCH",
		"nReturned" : 101,
		"executionTimeMillisEstimate" : 0,
		"works" : 101,
		"advanced" : 101,
		"needTime" : 0,
		"needYield" : 0,
		"saveState" : 1,
		"restoreState" : 0,
		"isEOF" : 0,
		"docsExamined" : 101,
		"alreadyHasObj" : 0,
		"inputStage" : {
			"stage" : "IXSCAN",
			"nReturned" : 101,
			"executionTimeMillisEstimate" : 0,
			"works" : 101,
			"advanced" : 101,
			"needTime" : 0,
			"needYield" : 0,
			"saveState" : 1,
			"restoreState" : 0,
			"isEOF" : 0,
			"keyPattern" : {
				"date" : 1
			},
			"indexName" : "date_1",
			"isMultiKey" : false,
			"multiKeyPaths" : {
				"date" : [ ]
			},
			"isUnique" : false,
			"isSparse" : false,
			"isPartial" : false,
			"indexVersion" : 2,
			"direction" : "forward",
			"indexBounds" : {
```
Время выполнения запроса уменьшилось за счет индексного сканирования;

- Пойдем в коллекцию листингов airbnb и включим там профилирование и сделаем запрос :

Найдем квартиру  с двумя спальнями В Бруклине :
```
db.listings.find({ $and :[{"address.market":"New York"}, {"address.suburb" : "Brooklyn"}, {"bedrooms" : 2}]}).pretty()
```
Посмотрим статистику :
```
	"responseLength" : 2488808,
	"protocol" : "op_msg",
	"millis" : 13,
	"planSummary" : "COLLSCAN",
	"execStats" : {
		"stage" : "COLLSCAN",
		"filter" : {
			"$and" : [
				{
					"address.market" : {
						"$eq" : "New York"
					}
				},
				{
					"address.suburb" : {
						"$eq" : "Brooklyn"
					}
				},
				{
					"bedrooms" : {
						"$eq" : 1
					}
				}
			]
		},
		"nReturned" : 101,
		"executionTimeMillisEstimate" : 1,
		"works" : 5475,
		"advanced" : 101,
		"needTime" : 5374,
		"needYield" : 0,
		"saveState" : 6,
		"restoreState" : 5,
		"isEOF" : 0,
		"direction" : "forward",
		"docsExamined" : 5474
```
Сделаем составной  индекс на Город и район :
```
db.listings.createIndex({"address.market" : 1,"address.suburb": 1})
{
	"createdCollectionAutomatically" : false,
	"numIndexesBefore" : 1,
	"numIndexesAfter" : 2,
	"ok" : 1
}
```
Посмотрим план :
```
	"protocol" : "op_msg",
	"millis" : 1,
	"planSummary" : "IXSCAN { address.market: 1, address.suburb: 1 }",
	"execStats" : {
		"stage" : "FETCH",
		"filter" : {
			"bedrooms" : {
				"$eq" : 2
			}
		},
		"nReturned" : 16,
		"executionTimeMillisEstimate" : 0,
		"works" : 130,
		"advanced" : 16,
		"needTime" : 113,
		"needYield" : 0,
		"saveState" : 0,
		"restoreState" : 0,
		"isEOF" : 1,
		"docsExamined" : 129,
		"alreadyHasObj" : 0,
		"inputStage" : {
			"stage" : "IXSCAN",
			"nReturned" : 129,
			"executionTimeMillisEstimate" : 0,
			"works" : 130,
			"advanced" : 129,
			"needTime" : 0,
			"needYield" : 0,
			"saveState" : 0,
			"restoreState" : 0,
			"isEOF" : 1,
			"keyPattern" : {
				"address.market" : 1,
				"address.suburb" : 1
			},
			"indexName" : "address.market_1_address.suburb_1",
			"isMultiKey" : false,
			"multiKeyPaths" : {
				"address.market" : [ ],
				"address.suburb" : [ ]
			},
			"isUnique" : false,
			"isSparse" : false,
			"isPartial" : false,
			"indexVersion" : 2,
			"direction" : "forward",
			"indexBounds" : {
				"address.market" : [
					"[\"New York\", \"New York\"]"
				],
				"address.suburb" : [
					"[\"Brooklyn\", \"Brooklyn\"]"
				]
			},
   ```
Получаем подтверждение использования индекса и ускорения запроса