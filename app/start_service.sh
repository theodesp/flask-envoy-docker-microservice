#!/bin/bash
set -xe
python3 ./app.py & envoy -c /etc/app-service-envoy.json --service-cluster app