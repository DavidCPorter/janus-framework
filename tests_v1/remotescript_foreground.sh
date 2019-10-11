#!/bin/bash
python3 traffic_gen.py --threads 6 --duration 10 --replicas 4 --shards 16 --query solrj --loop open --solrnum 8 --connections 1 --output-dir ./ --port 9222 --host 10.10.1.2 &
python3 traffic_gen.py --threads 6 --duration 10 --replicas 4 --shards 16 --query solrj --loop open --solrnum 8 --connections 1 --output-dir ./ --port 9333 --host 10.10.1.3 &
python3 traffic_gen.py --threads 6 --duration 10 --replicas 4 --shards 16 --query solrj --loop open --solrnum 8 --connections 1 --output-dir ./ --port 9444 --host 10.10.1.4 &
python3 traffic_gen.py --threads 6 --duration 10 --replicas 4 --shards 16 --query solrj --loop open --solrnum 8 --connections 1 --output-dir ./ --port 9111 --host 10.10.1.5 &
python3 traffic_gen.py --threads 6 --duration 10 --replicas 4 --shards 16 --query solrj --loop open --solrnum 8 --connections 1 --output-dir ./ --port 9222 --host 10.10.1.6 &
python3 traffic_gen.py --threads 6 --duration 10 --replicas 4 --shards 16 --query solrj --loop open --solrnum 8 --connections 1 --output-dir ./ --port 9333 --host 10.10.1.7 &
python3 traffic_gen.py --threads 6 --duration 10 --replicas 4 --shards 16 --query solrj --loop open --solrnum 8 --connections 1 --output-dir ./ --port 9444 --host 10.10.1.8 &
python3 traffic_gen.py --threads 6 --duration 10 --replicas 4 --shards 16 --query solrj --loop open --solrnum 8 --connections 1 --output-dir ./ --port 9111 --host 10.10.1.1
