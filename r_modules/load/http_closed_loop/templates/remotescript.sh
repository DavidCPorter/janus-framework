#!/bin/bash

{% for connection in range(l_procs | int) %}
python3 traffic_gen.py --threads 1 --duration {{load_duration}} --replicas {{l_replicas}} --shards {{l_shards}} --query {{l_query}} --loop {{l_loop}} --solrnum {{l_solrnum}}  --engine {{engine}} --connections 1 --output-dir ./ --host {{endpoint_host}}{{connection%2+1}} --port 9444 >/dev/null 2>&1 &
{% endfor %}
python3 traffic_gen.py --threads 1 --duration {{load_duration}} --replicas {{l_replicas}} --shards {{l_shards}} --query {{l_query}} --loop {{l_loop}} --solrnum {{l_solrnum}}  --engine {{engine}} --connections 1 --output-dir ./ --host {{endpoint_host}}2 --port 9444
sleep 3