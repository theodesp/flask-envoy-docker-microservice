# Front Proxy Gateway

This is the front service proxy that routes the
requests to the appropriate backend services.

We use [Envoy](https://www.envoyproxy.io/) together with the
configuration file `front-proxy-envoy` to create a

All incoming requests are routed via the front envoy, 
which is acting as a reverse proxy sitting on the edge of the 
envoymesh network. 

Port 80 is mapped to port 8000 by docker compose.
THus, all traffic that is routed by the front envoy to 
the service containers is actually routed to the 
service envoys. 
In turn the service envoys route the request to the 
flask app via the loopback address.