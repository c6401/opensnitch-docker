FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        iptables \
        libnetfilter-queue-dev \
        libpcap-dev \
        locales \
        gcc \
        golang-go \
        git \
        python3-pip \
        python3-venv \
        python3.6-dev \
        sudo \
        xorg

RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LC_ALL='en_US.UTF-8' LANGUAGE='en_US.UTF-8'

RUN python3 -mpip install grpcio-tools

RUN mkdir /opensnitch
RUN python3 -mvenv /opensnitch/venv

RUN /opensnitch/venv/bin/python -mpip install setuptools
RUN /opensnitch/venv/bin/python -mpip install git+git://github.com/Supervisor/supervisor.git

ENV GOPATH=/opensnitch/go
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin

RUN go get github.com/golang/protobuf/protoc-gen-go
RUN go get -u github.com/golang/dep/cmd/dep
RUN go get github.com/evilsocket/opensnitch; exit 0

WORKDIR $GOPATH/src/github.com/evilsocket/opensnitch
RUN make

WORKDIR $GOPATH/src/github.com/evilsocket/opensnitch/daemon
RUN make

WORKDIR $GOPATH/src/github.com/evilsocket/opensnitch/ui
RUN /opensnitch/venv/bin/python -mpip install -r requirements.txt
RUN /opensnitch/venv/bin/python -mpip install .

RUN useradd -m -s /bin/bash app
RUN mkdir ${GOPATH}/src/github.com/evilsocket/opensnitch/ui/rules

ENV HOME=/home/app

COPY supervisord.conf /opensnitch/supervisord.conf

CMD ["/opensnitch/venv/bin/supervisord", "-c", "/opensnitch/supervisord.conf"]

