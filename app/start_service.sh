#!/bin/bash
set -e

python3 /code/app.py & envoy -c /etc/app-service-envoy.json --service-cluster service
