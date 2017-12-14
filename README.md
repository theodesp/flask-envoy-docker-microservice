Flask on Envoy Cluster microservice example
---
A simple tutorial how to setup a Flask microservice using [Envoy](https://www.envoyproxy.io/) Service mesh and Docker.

## Running the service
**Step 1: Install Docker**

Ensure that you have a recent versions of 
`docker`, `docker-compose` and `docker-machine` 
installed.

**Step 2: Setup Docker Machine**

Create a new machine which will hold the containers:

```bash
$ docker-machine create --driver virtualbox default
$ eval $(docker-machine env default)
```
_**Tip**_
Run the bootstrap.sh program to perform the list of steps in one go.


**Step 3: Create configuration for Front End Envoy Gateway**
First create an Envoy config that will act as a Front End proxy server:

```bash
$ mkdir gateway
$ touch front-proxy-envoy.json
```

The configuration is a simple proxy redirect to a backend url:

```json
{
  "listeners": [
    {
      "address": "tcp://0.0.0.0:80",
      "filters": [
        {
          "name": "http_connection_manager",
          "config": {
            "codec_type": "auto",
            "stat_prefix": "ingress_http",
            "route_config": {
              "virtual_hosts": [
                {
                  "name": "app_backend",
                  "domains": [
                    "*"
                  ],
                  "routes": [
                    {
                      "timeout_ms": 0,
                      "prefix": "/",
                      "cluster": "app"
                    }
                  ]
                }
              ]
            },
            "filters": [
              {
                "name": "router",
                "config": {}
              }
            ]
          }
        }
      ]
    }
  ],
  "admin": {
    "access_log_path": "/dev/null",
    "address": "tcp://0.0.0.0:8001"
  },
  "cluster_manager": {
    "clusters": [
      {
        "name": "app",
        "connect_timeout_ms": 250,
        "type": "strict_dns",
        "lb_type": "round_robin",
        "features": "http2",
        "hosts": [
          {
            "url": "tcp://app:80"
          }
        ]
      }
    ]
  }
}


```

**Step 4: Add Dockerfile for Front End Envoy Gateway**

```bash
$ touch DockerFile
$ cat <<EOF > DockerFile
    FROM envoyproxy/envoy:latest

    RUN apt-get update && apt-get -q install -y \
        curl

    CMD /usr/local/bin/envoy -c /etc/front-proxy-envoy.json --service-cluster front-proxy
EOF

```

**Step 5: Create configuration for Back End Envoy Proxy Server**
First create an Envoy config that will act as a Back End proxy server. Make sure you match the listener address to the 
hosts address of the front-end proxy.


```json
{
  "listeners": [
    {
      "address": "tcp://0.0.0.0:80",
      "filters": [
        {
          "name": "http_connection_manager",
          "config": {
            "codec_type": "auto",
            "stat_prefix": "ingress_http",
            "route_config": {
              "virtual_hosts": [
                {
                  "name": "app",
                  "domains": [
                    "*"
                  ],
                  "routes": [
                    {
                      "timeout_ms": 0,
                      "prefix": "/",
                      "cluster": "local_service"
                    }
                  ]
                }
              ]
            },
            "filters": [
              {
                "name": "router",
                "config": {}
              }
            ]
          }
        }
      ]
    }
  ],
  "admin": {
    "access_log_path": "/dev/null",
    "address": "tcp://0.0.0.0:8001"
  },
  "cluster_manager": {
    "clusters": [
      {
        "name": "local_service",
        "connect_timeout_ms": 250,
        "type": "strict_dns",
        "lb_type": "round_robin",
        "hosts": [
          {
            "url": "tcp://127.0.0.1:8080"
          }
        ]
      }
    ]
  }
}


```

**Step 6: Add Dockerfile for Backend Envoy Gateway**

```bash
$ touch DockerFile
$ cat <<EOF > DockerFile
    FROM envoyproxy/envoy:latest


    RUN apt-get update && apt-get -q install -y \
        curl \
        software-properties-common \
        python-software-properties
    RUN add-apt-repository ppa:deadsnakes/ppa
    RUN apt-get update && apt-get -q install -y \
        python3 \
        python3-pip
    RUN python3 --version && pip3 --version
    
    RUN mkdir /code
    COPY . /code
    WORKDIR /code
    
    RUN pip3 install -r ./requirements.txt
    ADD ./start_service.sh /usr/local/bin/start_service.sh
    RUN chmod u+x /usr/local/bin/start_service.sh
    
    ENTRYPOINT /usr/local/bin/start_service.sh
EOF
```

add also a start up shell for your app

```bash
$ touch start_service.sh
$ cat <<EOF > start_service.sh
    #!/bin/bash
    set -xe
    python3 ./app.py & envoy -c /etc/app-service-envoy.json --service-cluster app
EOF

```

**Step 7: Add docker-compose script for setting up all containers**

```bash
$ touch docker-compose.yml
cat<<EOF > docker-compose.yml
version: '2'
services:

  front-envoy:
    build:
      context: .
      dockerfile: gateway/Dockerfile
    volumes:
      - ./gateway/front-proxy-envoy.json:/etc/front-proxy-envoy.json
    networks:
      - envoymesh
    expose:
      - "80"
      - "8001"
    ports:
      - "8000:80"
      - "8001:8001"

  app:
    build:
      context: ./app
      dockerfile: Dockerfile
    volumes:
      - ./app/app-service-envoy.json:/etc/app-service-envoy.json
    networks:
      envoymesh:
        aliases:
          - app
    expose:
      - "80"

networks:
  envoymesh: {}

EOF
```

**Step 8: Add requirements.txt and flask app**
Create the basic flask micro-service and add the following code.

```bash
$ touch requirements.txt
$ cat<<EOF > requirements.txt
Flask==0.12.2
gunicorn==18.0
python-dotenv==0.7.1
EOF

$ touch app.py

```

*app.py*
```python
from flask import Flask
import settings


def init():
    """ Create a Flask app. """
    server = Flask(__name__)

    return server

app = init()


@app.route('/')
def index():
    return 'My awesome micro-service'

if __name__ == "__main__":
    app.run(
        host=settings.API_BIND_HOST,
        port=settings.API_BIND_PORT,
        debug=settings.DEBUG)
```

*settings.py*
```python
"""
Settings file, which is populated from the environment while enforcing common
use-case defaults.
"""
import os
from os.path import join, dirname
from dotenv import load_dotenv

dotenv_path = join(dirname(__file__), '.env')
load_dotenv(dotenv_path)

# OR, the same with increased verbosity:
load_dotenv(dotenv_path, verbose=True)


DEBUG = True
if os.getenv('DEBUG', '').lower() in ['0', 'no', 'false']:
    DEBUG = False

API_BIND_HOST = os.getenv('SERVICE_API_HOST', '127.0.0.1')
API_BIND_PORT = int(os.getenv('SERVICE_API_PORT', 8080))
SERVICE_NAME = os.getenv('SERVICE_NAME', 'app')

```

**Step 9: Test the service locally**
```bash
$ python app.py                                       
 * Running on http://127.0.0.1:8080/ (Press CTRL+C to quit)
 * Restarting with stat
 * Debugger is active!
 * Debugger PIN: 185-774-130

```

and in another terminal

```bash
$ curl http://127.0.0.1:8080/
My awesome micro-service%                 
```


**Step 10: Start all containers**

```bash
$ docker-compose up --build -d
$ docker-compose ps
        Name                       Command               State      Ports
-------------------------------------------------------------------------------------------------------------
app_service_1      /bin/sh -c /usr/local/bin/ ...    Up       80/tcp
front-proxy-envoy_1   /bin/sh -c /usr/local/bin/ ...    Up       0.0.0.0:8000->80/tcp, 0.0.0.0:8001->8001/tcp
```

**Step 11: Test routing capabilities**

You can now send a request to services 
via the front-envoy.

```bash
curl -X GET -v $(docker-machine ip default):8000
* Rebuilt URL to: 0.0.0.0:8000/
*   Trying 0.0.0.0...
* TCP_NODELAY set
* Connected to 0.0.0.0 (0.0.0.0) port 8000 (#0)
> GET / HTTP/1.1
> Host: 0.0.0.0:8000
> User-Agent: curl/7.54.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< content-type: text/html; charset=utf-8
< content-length: 24
< server: envoy
< date: Thu, 14 Dec 2017 08:51:39 GMT
< x-envoy-upstream-service-time: 4
< 
* Connection #0 to host 0.0.0.0 left intact
My awesome micro-service%                        
```

**Step 12: Enjoy your micro-service and have some Beer 🍺🍺🍺**


LICENCE
---
MIT @ Theo Despoudis