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
