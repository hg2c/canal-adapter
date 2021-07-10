FROM canal/osbase:v1

MAINTAINER Luo Tao (luotao@easi.com.au)

RUN \
    mkdir -p /opt/canal-adapter && \
    wget -nv -P /opt https://github.com/alibaba/canal/releases/download/canal-1.1.5/canal.adapter-1.1.5.tar.gz && \
    tar -xzvf /opt/canal.adapter-1.1.5.tar.gz -C /opt/canal-adapter && \
    /bin/rm -f /opt/canal.adapter-1.1.5.tar.gz && \

    yum clean all && \
    true

COPY app.sh /app.sh

WORKDIR /opt/canal-adapter
CMD [ "/app.sh" ]
