curl http://10.10.1.2:9200/reviews -X PUT -H 'Content-type:application/json' --data-binary '{
"settings": {
   "index": {
         "number_of_shards": 1,
         "number_of_replicas": 1
   },
   "analysis": {
     "analyzer": {
       "analyzer-name": {
             "type": "custom",
             "tokenizer": "keyword",
             "filter": "lowercase"
       }
     }
   }
 }
}'
