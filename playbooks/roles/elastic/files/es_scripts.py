import os
import sys

# Import Elasticsearch package
from elasticsearch import Elasticsearch
# Connect to the elastic cluster
from elasticsearch import helpers


def gendata(iname):
    with open("reviews_Electronics_5.json", "r") as f:
        for line in f.readlines():
            yield {
                "_index": iname,
                "_type": "_doc",
                "_source": line
            }

def delete_index():
    es=Elasticsearch([{'host':"10.10.1.1",'port':9200}])
    response=es.indices.delete(index='reviews', ignore=400)
    print(response[:100])

def main(shards,replicas,iname):

    mapping = {
        "settings": {
            "number_of_shards": shards,
            "number_of_replicas": replicas
        },
        "mappings": {
            "properties": {
                "reviewerID": {
                    "type": "text" # formerly "string"
                },
                "asin": {
                    "type": "text"
                },
                "reviewerName": {
                    "type": "text"
                },
                "reviewText": {
                    "type": "text"
                },
                "overall": {
                    "type": "double"
                },
                "summary": {
                    "type": "text"
                }
            }
        }
    }


    es=Elasticsearch([{'host':"10.10.1.1",'port':9200}])
    response=es.indices.create(
    index=iname,
    body=mapping,
    ignore=400
    )

    if 'acknowledged' in response:
        if response['acknowledged'] == True:
            print ("INDEX MAPPING SUCCESS FOR INDEX:", response['index'])

    # catch API error response
    elif 'error' in response:
        print ("ERROR:", response['error']['root_cause'])
        print ("TYPE:", response['error']['type'])


    helpers.bulk(es, gendata(iname))





if __name__ == "__main__":

    if len(sys.argv) != 4:
        print("3 args required <shards> <replicas> <index_name>")
        sys.exit()
    shards=sys.argv[1]
    replicas=sys.argv[2]
    iname=sys.argv[3]
    #delete_index()
    main(shards,replicas,iname)
    sys.exit()
