import os
import sys
import urllib3
import http.client
import json


def add_conn():
    conn = http.client.HTTPConnection("128.110.154.12",8983,timeout=5)
    return conn


def delete_collections():
    con = add_conn()
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
    delete_collections()
    # delete_collections(c)
    sys.exit()
