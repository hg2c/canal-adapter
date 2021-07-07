FROM canal/osbase:v1

MAINTAINER Luo Tao (lotreal@gmail.com)

# install canal
COPY canal.adapter-*.tar.gz /opt/

RUN \
    mkdir -p /opt/canal-adapter && \
    tar -xzvf /opt/canal.adapter-*.tar.gz -C /opt/canal-adapter && \
    /bin/rm -f /opt/canal.adapter-*.tar.gz && \

    yum clean all && \
    true

COPY app.sh /app.sh

WORKDIR /opt/canal-adapter
CMD [ "/app.sh" ]
