FROM canal/osbase:v1

MAINTAINER Luo Tao (luotao@easi.com.au)

RUN \
    mkdir -p /opt/canal-adapter && \
    wget -nv -P /opt https://github.com/alibaba/canal/releases/download/canal-1.1.5/canal.adapter-1.1.5.tar.gz && \
    tar -xzvf /opt/canal.adapter-1.1.5.tar.gz -C /opt/canal-adapter && \
    /bin/rm -f /opt/canal.adapter-1.1.5.tar.gz && \

    yum clean all && \
    true

RUN wget -nv -P /opt/canal-adapter/lib/ https://downloads.mariadb.com/Connectors/java/connector-java-2.7.3/mariadb-java-client-2.7.3.jar

COPY app.sh /app.sh
COPY application.yml /opt/canal-adapter/conf/application.yml

WORKDIR /opt/canal-adapter
CMD [ "/app.sh" ]
