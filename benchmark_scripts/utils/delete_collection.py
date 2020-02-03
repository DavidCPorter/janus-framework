import os
import sys
import urllib3
import http.client
import json


def add_conn(port):
    conn = http.client.HTTPConnection("128.110.153.169",port,timeout=10)
    return conn


def delete_collections(port):
    con = add_conn(port)
    try:
        con.request( "GET", "/solr/admin/collections?action=LIST")
        resp = con.getresponse()
        r = resp.read()
        x = r.decode("utf-8")
        y = json.loads(x)
        for collection in y['collections']:
            try:
                con.request("GET", "/solr/admin/collections?action=DELETE&name="+collection)
                resp = con.getresponse()
                print(resp.read())
            except Exception as e:
                print( "Error while requesting list collection %s" % e )

    except Exception as e:
        print( "Error while requesting list collection %s" % e )
    con.close()

    return



if __name__ == "__main__":
    if sys.argv[1] == None:
        port=8983
    else:
        port = sys.argv[1]
    delete_collections(port)
    # delete_collections(c)
    sys.exit()
