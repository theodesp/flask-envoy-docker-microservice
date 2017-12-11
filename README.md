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
                  "domains": ["*"],
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
First create an Envoy config that will act as a Back End proxy server:


**Step 4: Start all containers**

```bash
$ docker-compose up --build -d
$ docker-compose ps
        Name                       Command               State      Ports
-------------------------------------------------------------------------------------------------------------
app_service_1      /bin/sh -c /usr/local/bin/ ...    Up       80/tcp
front-proxy-envoy_1   /bin/sh -c /usr/local/bin/ ...    Up       0.0.0.0:8000->80/tcp, 0.0.0.0:8001->8001/tcp
```

**Step 4: Test routing capabilities**

You can now send a request to services 
via the front-envoy.

```bash
curl -X GET -v $(docker-machine ip default):8000
```