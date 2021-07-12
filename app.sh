#!/bin/bash

export LANG=en_US.UTF-8

if [ -z "$BASE" ] ; then
    BASE=/opt/canal-adapter
fi

cd $BASE

CANAL_INSTANCE_MASTER_ADDRESS=$(perl -le 'print $ENV{"canal.instance.master.address"}')
CANAL_INSTANCE_DATABASE=$(perl -le 'print $ENV{"canal.instance.database"}')
CANAL_INSTANCE_USERNAME=$(perl -le 'print $ENV{"canal.instance.dbUsername"}')
CANAL_INSTANCE_PASSWORD=$(perl -le 'print $ENV{"canal.instance.dbPassword"}')

CANAL_DESTINATIONS=$(perl -le 'print $ENV{"canal.destinations"} || "cdc"')
CDC_MYSQL_JDBC_URL=$(perl -le 'print $ENV{"cdc.mysql.jdbc.url"}')

CANAL_TCP_SERVER_HOST=$(perl -le 'print $ENV{"canal.tcp.server.host"} || "127.0.0.1:11111"')
sed -i "s/    canal.tcp.server.host: .*/    canal.tcp.server.host: ${CANAL_TCP_SERVER_HOST}/" $BASE/conf/application.yml

# sed -i "s|#  srcDataSources:|  srcDataSources:|" $BASE/conf/application.yml
# sed -i "s|#    defaultDS:|    defaultDS:|" $BASE/conf/application.yml
# sed -i "s|#      url: jdbc:mysql://127.0.0.1:3306/mytest?useUnicode=true|      url: \"jdbc:mysql://${CANAL_INSTANCE_MASTER_ADDRESS}/${CANAL_INSTANCE_DATABASE}?useUnicode=true\&characterEncoding=utf-8\&enabledTLSProtocols=TLSv1.2\"|" $BASE/conf/application.yml
# sed -i "s|#      username: root|      username: \"${CANAL_INSTANCE_USERNAME}\"|" $BASE/conf/application.yml
# sed -i "s|#      password: 121212|      password: \"${CANAL_INSTANCE_PASSWORD}\"|" $BASE/conf/application.yml

if [ ! -z "$CDC_MYSQL_JDBC_URL" ] ; then
    echo "enable mysql cdc!"
    CDC_MYSQL_JDBC_DRIVER=$(perl -le 'print $ENV{"cdc.mysql.jdbc.driver"}')
    CDC_MYSQL_JDBC_USERNAME=$(perl -le 'print $ENV{"cdc.mysql.jdbc.username"}')
    CDC_MYSQL_JDBC_PASSWORD=$(perl -le 'print $ENV{"cdc.mysql.jdbc.password"}')
    CDC_MYSQL_JDBC_DATABASE=$(perl -le 'print $ENV{"cdc.mysql.jdbc.database"}')

    sed -i "s/  - instance: .*/  - instance: ${CANAL_DESTINATIONS}/" $BASE/conf/application.yml

    cat <<EOF>> $BASE/conf/application.yml
      - name: rdb
        key: mysql1
        properties:
          jdbc.driverClassName: "${CDC_MYSQL_JDBC_DRIVER}"
          jdbc.url: "${CDC_MYSQL_JDBC_URL}"
          jdbc.username: "${CDC_MYSQL_JDBC_USERNAME}"
          jdbc.password: "${CDC_MYSQL_JDBC_PASSWORD}"
EOF

    # rm $BASE/conf/rdb/mytest_user.yml
    cat <<EOF> $BASE/conf/rdb/mytest_user.yml
dataSourceKey: defaultDS
destination: ${CANAL_DESTINATIONS}
groupId: g1
outerAdapterKey: mysql1
concurrent: true
dbMapping:
  mirrorDb: true
  database: ${CDC_MYSQL_JDBC_DATABASE}
EOF
fi

echo ---
cat $BASE/conf/application.yml
echo ---
cat $BASE/conf/rdb/mytest_user.yml

## set java path
if [ -z "$JAVA" ] ; then
  JAVA=$(which java)
fi

case "$#"
in
0 )
  ;;
2 )
  if [ "$1" = "debug" ]; then
    DEBUG_PORT=$2
    DEBUG_SUSPEND="n"
    JAVA_DEBUG_OPT="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=$DEBUG_PORT,server=y,suspend=$DEBUG_SUSPEND"
  fi
  ;;
* )
  echo "THE PARAMETERS MUST BE TWO OR LESS.PLEASE CHECK AGAIN."
  exit;;
esac


JAVA_OPTS="-server -Xms2048m -Xmx3072m -Xmn1024m -XX:SurvivorRatio=2 -XX:PermSize=96m -XX:MaxPermSize=256m -Xss256k -XX:-UseAdaptiveSizePolicy -XX:MaxTenuringThreshold=15 -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:+HeapDumpOnOutOfMemoryError"
JAVA_OPTS=" $JAVA_OPTS -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8"
ADAPTER_OPTS="-DappName=canal-adapter"

for i in $BASE/lib/*;
    do CLASSPATH=$i:"$CLASSPATH";
done

CLASSPATH="$BASE/conf:$CLASSPATH";

# echo CLASSPATH :$CLASSPATH
$JAVA $JAVA_OPTS $JAVA_DEBUG_OPT $ADAPTER_OPTS -classpath .:$CLASSPATH com.alibaba.otter.canal.adapter.launcher.CanalAdapterApplication
