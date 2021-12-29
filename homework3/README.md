# mongo_otus

# ДЗ № 3

## В процессе сделано:

- Используем terraform и ansible из дз2 для развертывания инстанса mongo;
- Скачивааем dataset  stocks  и  развертываем в инстансе c помощью mongorestore:

```
mongorestore dump --port 27019 -u mongo -p password
2021-12-29T08:29:17.020+0000	WARNING: On some systems, a password provided directly using --password may be visible to system status programs such as `ps` that may be invoked by other users. Consider omitting the password to provide it via stdin, or using the --config option to specify a configuration file with the password.
2021-12-29T08:29:17.036+0000	preparing collections to restore from
2021-12-29T08:29:17.037+0000	no metadata; falling back to system.indexes
2021-12-29T08:29:17.058+0000	restoring stocks.values from dump/stocks/values.bson
2021-12-29T08:29:20.036+0000	[#.......................]  stocks.values  45.0MB/715MB  (6.3%)
2021-12-29T08:29:23.038+0000	[###.....................]  stocks.values  91.5MB/715MB  (12.8%)
2021-12-29T08:29:26.036+0000	[####....................]  stocks.values  137MB/715MB  (19.2%)
2021-12-29T08:29:29.038+0000	[######..................]  stocks.values  183MB/715MB  (25.6%)
2021-12-29T08:29:32.037+0000	[#######.................]  stocks.values  229MB/715MB  (32.1%)
2021-12-29T08:29:35.038+0000	[#########...............]  stocks.values  276MB/715MB  (38.6%)
2021-12-29T08:29:38.036+0000	[##########..............]  stocks.values  322MB/715MB  (45.0%)
2021-12-29T08:29:41.036+0000	[############............]  stocks.values  368MB/715MB  (51.5%)
2021-12-29T08:29:44.036+0000	[#############...........]  stocks.values  415MB/715MB  (58.0%)
2021-12-29T08:29:47.036+0000	[###############.........]  stocks.values  461MB/715MB  (64.4%)
2021-12-29T08:29:50.036+0000	[################........]  stocks.values  507MB/715MB  (70.8%)
2021-12-29T08:29:53.038+0000	[##################......]  stocks.values  550MB/715MB  (76.9%)
2021-12-29T08:29:56.038+0000	[###################.....]  stocks.values  595MB/715MB  (83.2%)
2021-12-29T08:29:59.036+0000	[#####################...]  stocks.values  642MB/715MB  (89.8%)
2021-12-29T08:30:02.036+0000	[#######################.]  stocks.values  688MB/715MB  (96.2%)
2021-12-29T08:30:03.867+0000	[########################]  stocks.values  715MB/715MB  (100.0%)
2021-12-29T08:30:03.867+0000	finished restoring stocks.values (4308303 documents, 0 failures)
2021-12-29T08:30:03.867+0000	no indexes to restore for collection stocks.values
2021-12-29T08:30:03.867+0000	4308303 document(s) restored successfully. 0 document(s) failed to restore.
```

- Попробуем также использование  mongoimport - listing airbnb:

```
mongoimport --db airbnb --collection listings --port 27019           --authenticationDatabase admin --username mongo --password password           --drop --file listingsAndReviews.json
2021-12-29T08:43:02.025+0000	connected to: mongodb://localhost:27019/
2021-12-29T08:43:02.025+0000	dropping: airbnb.listings
2021-12-29T08:43:05.026+0000	[#############...........] airbnb.listings	53.4MB/95.0MB (56.2%)
2021-12-29T08:43:07.544+0000	[########################] airbnb.listings	95.0MB/95.0MB (100.0%)
2021-12-29T08:43:07.544+0000	5555 document(s) imported successfully. 0 document(s) failed to import.
```

```
show dbs
admin   0.000GB
airbnb  0.050GB
config  0.000GB
local   0.000GB
stocks  0.217GB
```

- Поселектим базу stocks :
Найдем акции  которые торговались 2006-08-03 и на открытии стоили  дешевле 10$:
```
db.values.find({"date" : "2006-08-03", open: { $lt: 10 } } )
```

```
{ "_id" : ObjectId("4d094f58c96767d7a009a2d1"), "exchange" : "NASDAQ", "stock_symbol" : "AAME", "date" : "2006-08-03", "open" : 2.7, "high" : 2.87, "low" : 2.7, "close" : 2.72, "volume" : 3200, "adj close" : 2.72 }
{ "_id" : ObjectId("4d094f58c96767d7a009e980"), "exchange" : "NASDAQ", "stock_symbol" : "AATI", "date" : "2006-08-03", "open" : 8.52, "high" : 8.67, "low" : 8.37, "close" : 8.55, "volume" : 463000, "adj close" : 8.55 }
{ "_id" : ObjectId("4d094f58c96767d7a00a4ae6"), "exchange" : "NASDAQ", "stock_symbol" : "ABMC", "date" : "2006-08-03", "open" : 0.94, "high" : 0.96, "low" : 0.92, "close" : 0.95, "volume" : 88500, "adj close" : 0.95 }
{ "_id" : ObjectId("4d094f58c96767d7a00a6b98"), "exchange" : "NASDAQ", "stock_symbol" : "ABPI", "date" : "2006-08-03", "open" : 2.87, "high" : 3.09, "low" : 2.75, "close" : 3.09, "volume" : 35600, "adj close" : 3.09 }
{ "_id" : ObjectId("4d094f58c96767d7a00a6de7"), "exchange" : "NASDAQ", "stock_symbol" : "ABTL", "date" : "2006-08-03", "open" : 3.16, "high" : 3.4, "low" : 3.12, "close" : 3.22, "volume" : 410500, "adj close" : 3.22 }
{ "_id" : ObjectId("4d094f59c96767d7a00a7cc4"), "exchange" : "NASDAQ", "stock_symbol" : "ABXA", "date" : "2006-08-03", "open" : 5.31, "high" : 5.37, "low" : 5.2, "close" : 5.31, "volume" : 205300, "adj close" : 5.31 }
{ "_id" : ObjectId("4d094f59c96767d7a00a8150"), "exchange" : "NASDAQ", "stock_symbol" : "ACAD", "date" : "2006-08-03", "open" : 6.29, "high" : 6.36, "low" : 6.16, "close" : 6.19, "volume" : 176400, "adj close" : 6.19 }
{ "_id" : ObjectId("4d094f59c96767d7a00aaf61"), "exchange" : "NASDAQ", "stock_symbol" : "ACCL", "date" : "2006-08-03", "open" : 6.3, "high" : 6.62, "low" : 6.28, "close" : 6.28, "volume" : 38200, "adj close" : 6.28 }
{ "_id" : ObjectId("4d094f59c96767d7a00abb66"), "exchange" : "NASDAQ", "stock_symbol" : "ACEL", "date" : "2006-08-03", "open" : 1.99, "high" : 2, "low" : 1.9, "close" : 1.91, "volume" : 54100, "adj close" : 1.91 }
{ "_id" : ObjectId("4d094f59c96767d7a00ac6f0"), "exchange" : "NASDAQ", "stock_symbol" : "ACET", "date" : "2006-08-03", "open" : 6.81, "high" : 6.81, "low" : 6.71, "close" : 6.8, "volume" : 5100, "adj close" : 6.53 }
{ "_id" : ObjectId("4d094f59c96767d7a00b01d0"), "exchange" : "NASDAQ", "stock_symbol" : "ACLS", "date" : "2006-08-03", "open" : 5.58, "high" : 5.76, "low" : 5.49, "close" : 5.73, "volume" : 2159900, "adj close" : 5.73 }
{ "_id" : ObjectId("4d094f59c96767d7a00b0951"), "exchange" : "NASDAQ", "stock_symbol" : "ACME", "date" : "2006-08-03", "open" : 5.08, "high" : 5.3, "low" : 5.02, "close" : 5.3, "volume" : 5500, "adj close" : 4.84 }
{ "_id" : ObjectId("4d094f59c96767d7a00b1bc3"), "exchange" : "NASDAQ", "stock_symbol" : "ACOR", "date" : "2006-08-03", "open" : 3.16, "high" : 3.24, "low" : 3.07, "close" : 3.07, "volume" : 6200, "adj close" : 3.07 }
{ "_id" : ObjectId("4d094f59c96767d7a00b1dcc"), "exchange" : "NASDAQ", "stock_symbol" : "ACPW", "date" : "2006-08-03", "open" : 3.16, "high" : 3.16, "low" : 2.94, "close" : 3.03, "volume" : 83500, "adj close" : 3.03 }
{ "_id" : ObjectId("4d094f59c96767d7a00b2539"), "exchange" : "NASDAQ", "stock_symbol" : "ACSEF", "date" : "2006-08-03", "open" : 3.46, "high" : 3.5, "low" : 3.36, "close" : 3.46, "volume" : 11800, "adj close" : 3.46 }
{ "_id" : ObjectId("4d094f59c96767d7a00b33a5"), "exchange" : "NASDAQ", "stock_symbol" : "ACTI", "date" : "2006-08-03", "open" : 4.68, "high" : 4.69, "low" : 4.5, "close" : 4.63, "volume" : 61900, "adj close" : 4.63 }
{ "_id" : ObjectId("4d094f59c96767d7a00b46fd"), "exchange" : "NASDAQ", "stock_symbol" : "ACTS", "date" : "2006-08-03", "open" : 7.21, "high" : 7.4, "low" : 7.21, "close" : 7.27, "volume" : 34300, "adj close" : 7.27 }
{ "_id" : ObjectId("4d094f59c96767d7a00b4937"), "exchange" : "NASDAQ", "stock_symbol" : "ACTU", "date" : "2006-08-03", "open" : 3.98, "high" : 4.05, "low" : 3.98, "close" : 4.05, "volume" : 122900, "adj close" : 4.05 }
{ "_id" : ObjectId("4d094f59c96767d7a00b52a2"), "exchange" : "NASDAQ", "stock_symbol" : "ACUS", "date" : "2006-08-03", "open" : 2.9, "high" : 2.95, "low" : 2.81, "close" : 2.85, "volume" : 164900, "adj close" : 2.85 }
{ "_id" : ObjectId("4d094f59c96767d7a00b6d6d"), "exchange" : "NASDAQ", "stock_symbol" : "ADAM", "date" : "2006-08-03", "open" : 5.45, "high" : 5.47, "low" : 5.24, "close" : 5.4, "volume" : 30700, "adj close" : 5.4 }
Type "it" for more
```

- Найдем акции ,которые на закрытии биржи NASDAQ  2006-07-07 дня  стоили меньше  15 и обьем торгов был больше 10млн и отобразим имя акции,стоимость закрытия и обьем  торгов:
```
> db.values.find ({ $and :[{"date" : "2006-07-07"}, {"exchange" : "NASDAQ"}, {close: { $lt: 15 }}, {volume: { $gt: 10000000}}]}, {"stock_symbol": 1, "close": 1, "volume":1})
```

```
{ "_id" : ObjectId("4d094f61c96767d7a014ec91"), "stock_symbol" : "ATML", "close" : 5.18, "volume" : NumberLong(10541900) }
{ "_id" : ObjectId("4d094f74c96767d7a022373a"), "stock_symbol" : "CNXT", "close" : 2.19, "volume" : NumberLong(14726600) }
{ "_id" : ObjectId("4d095007c96767d7a043da47"), "stock_symbol" : "FNSR", "close" : 3.2, "volume" : NumberLong(23649200) }
```

- Найдем три самые дорогие акции  на дату  открытия за все время на бирже NASDAQ :

```
db.values.find().sort( { "open": -1, "exchange": 1 } ).pretty().limit(3)
```
Получаем ошибку:
```
error: error: {
	"ok" : 0,
	"errmsg" : "Executor error during find command :: caused by :: Sort exceeded memory limit of 104857600 bytes, but did not opt in to external sorting.",
	"code" : 292,
	"codeName" : "QueryExceededMemoryLimitNoDiskUseAllowed"
}
```
Создадим pipeline aggregate и подключим сортировку на диске :
```
db.values.aggregate( [
      { $sort : { "open": -1, "exchange": 1 } },
      { $limit : 3 }
   ],
   { allowDiskUse: true })
```
```
 "_id" : ObjectId("4d094f61c96767d7a014b3c9"), "exchange" : "NASDAQ", "stock_symbol" : "ATCO", "date" : "2000-03-16", "open" : 31007, "high" : 9.38, "low" : 9.38, "close" : 9.38, "volume" : 900, "adj close" : 9.38 }
{ "_id" : ObjectId("4d094f62c96767d7a0163bbe"), "exchange" : "NASDAQ", "stock_symbol" : "AWRE", "date" : "2000-06-06", "open" : 29595, "high" : 51.5, "low" : 55, "close" : 51.25, "volume" : 5500, "adj close" : 51.25 }
{ "_id" : ObjectId("4d095008c96767d7a044baef"), "exchange" : "NASDAQ", "stock_symbol" : "FSCI", "date" : "2000-05-18", "open" : 15713, "high" : 74.5, "low" : 74.5, "close" : 70, "volume" : 7000, "adj close" : 67.85 }
```

- И попробуем тоже самое без пайплайна:
```
db.values.find().sort( { "open": -1, "exchange": 1 } ).allowDiskUse().limit(3)
```

```
 "_id" : ObjectId("4d094f61c96767d7a014b3c9"), "exchange" : "NASDAQ", "stock_symbol" : "ATCO", "date" : "2000-03-16", "open" : 31007, "high" : 9.38, "low" : 9.38, "close" : 9.38, "volume" : 900, "adj close" : 9.38 }
{ "_id" : ObjectId("4d094f62c96767d7a0163bbe"), "exchange" : "NASDAQ", "stock_symbol" : "AWRE", "date" : "2000-06-06", "open" : 29595, "high" : 51.5, "low" : 55, "close" : 51.25, "volume" : 5500, "adj close" : 51.25 }
{ "_id" : ObjectId("4d095008c96767d7a044baef"), "exchange" : "NASDAQ", "stock_symbol" : "FSCI", "date" : "2000-05-18", "open" : 15713, "high" : 74.5, "low" : 74.5, "close" : 70, "volume" : 7000, "adj close" : 67.85 }
```

- Посчитаем количество тикетов на бирже:
```
db.values.distinct("stock_symbol").length
1618
```

- Посчитаем суммарный обьем торгов на бирже NASDAQ 2006-08-03:
```
db.values.aggregate( 
  [
      { $match : { "date": "2006-08-03" } },
      { $group: { _id: "$exchange",totalAmount: { $sum: "$volume"} } }
   ],
   { allowDiskUse: true })

{ "_id" : "NASDAQ", "totalAmount" : NumberLong(871831600) }
```
- Сделаем insert новой записи  от  сегодняшнего дня :
```
db.values.insert( { "exchange" : "NASDAQ", "stock_symbol" : "ADAM", "date" : "2021-12-29", "open" : 1, "high" : 10, "low" : 8, "close" : 7, "volume" : 20000, "adj close" :7.4 } )
WriteResult({ "nInserted" : 1 })
```
Найдем нашу запись
```
> db.values.find({"date" : "2021-12-29" } )
{ "_id" : ObjectId("61cc4a8e1746e48de32b43e7"), "exchange" : "NASDAQ", "stock_symbol" : "ADAM", "date" : "2021-12-29", "open" : 1, "high" : 10, "low" : 8, "close" : 7, "volume" : 20000, "adj close" : 7.4 }
```
- Добавим новую запись сегодняшнего дня с явным указанием id :
```
db.values.insert( {_id: 101, "exchange" : "NASDAQ", "stock_symbol" : "TASK", "date" : "2021-12-29", "open" : 1, "high" : 9, "low" : 8, "close" : 8, "volume" : 20000, "adj close" :7.4 } )
WriteResult({ "nInserted" : 1 })
```
```
> db.values.find({"date" : "2021-12-29" } )
{ "_id" : ObjectId("61cc4a8e1746e48de32b43e7"), "exchange" : "NASDAQ", "stock_symbol" : "ADAM", "date" : "2021-12-29", "open" : 1, "high" : 10, "low" : 8, "close" : 7, "volume" : 20000, "adj close" : 7.4 }
{ "_id" : 101, "exchange" : "NASDAQ", "stock_symbol" : "TASK", "date" : "2021-12-29", "open" : 1, "high" : 9, "low" : 8, "close" : 8, "volume" : 20000, "adj close" : 7.4 }
```

- Удалим все сегодняшние записи :
```
db.values.deleteMany({"date" : "2021-12-29"})
{ "acknowledged" : true, "deletedCount" : 2 }
```