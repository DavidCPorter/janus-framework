#!/bin/bash

{% for connection in range(procs | int) %}
python3 traffic_gen.py --threads 1 --duration {{load_duration}} --replicas {{replicas}} --shards {{shards}} --query {{query}} --loop {{loop}} --solrnum {{solrnum}}  --engine {{engine}} --connections 1 --output-dir ./ --host {{endpoint_host}}{{connection%2+1}} --port 9444 >/dev/null 2>&1 &
{% endfor %}
python3 traffic_gen.py --threads 1 --duration {{load_duration}} --replicas {{replicas}} --shards {{shards}} --query {{query}} --loop {{loop}} --solrnum {{solrnum}}  --engine {{engine}} --connections 1 --output-dir ./ --host {{endpoint_host}}2 --port 9444
sleep 3