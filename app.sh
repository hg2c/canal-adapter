#!/bin/bash

export LANG=en_US.UTF-8

BASE=/opt/canal-adapter

CDC_MASTER_CANAL=${CDC_MASTER_CANAL:-127.0.0.1:11111}
CDC_INSTANCE=${CDC_INSTANCE:-cdc}

CDC_SLAVE_JDBC_DRIVER=${CDC_SLAVE_JDBC_DRIVER:-org.mariadb.jdbc.Driver}

sed -i "s/    canal.tcp.server.host: .*/    canal.tcp.server.host: ${CDC_MASTER_CANAL}/" $BASE/conf/application.yml

# sed -i "s|#  srcDataSources:|  srcDataSources:|" $BASE/conf/application.yml
# sed -i "s|#    defaultDS:|    defaultDS:|" $BASE/conf/application.yml
# sed -i "s|#      url: jdbc:mysql://127.0.0.1:3306/mytest?useUnicode=true|      url: \"jdbc:mysql://${CDC_MASTER_ADDRESS}/${CDC_MASTER_DATABASE}?useUnicode=true\&characterEncoding=utf-8\&enabledTLSProtocols=TLSv1.2\"|" $BASE/conf/application.yml
# sed -i "s|#      username: root|      username: \"${CDC_MASTER_USERNAME}\"|" $BASE/conf/application.yml
# sed -i "s|#      password: 121212|      password: \"${CDC_MASTER_PASSWORD}\"|" $BASE/conf/application.yml

if [ -z "$CDC_LOG" ] ; then
    sed -i "s/      - name: logger/#      - name: logger/" $BASE/conf/application.yml
fi

if [ ! -z "$CDC_SLAVE_URL" ] ; then
    echo "enable rdb adapter!"
    sed -i "s/  - instance: .*/  - instance: ${CDC_INSTANCE}/" $BASE/conf/application.yml
    cat <<EOF>> $BASE/conf/application.yml

      - name: rdb
        key: cdc
        properties:
          jdbc.driverClassName: "${CDC_SLAVE_JDBC_DRIVER}"
          jdbc.url: "${CDC_SLAVE_URL}"
          jdbc.username: "${CDC_SLAVE_USERNAME}"
          jdbc.password: "${CDC_SLAVE_PASSWORD}"
EOF

    rm $BASE/conf/rdb/mytest_user.yml
    cat <<EOF> $BASE/conf/rdb/cdc.yml
dataSourceKey: defaultDS
destination: ${CDC_INSTANCE}
groupId: g1
outerAdapterKey: cdc
concurrent: true
dbMapping:
  mirrorDb: true
  database: ${CDC_SLAVE_DATABASE}
EOF
fi

echo ---
cat $BASE/conf/application.yml
echo ---
cat $BASE/conf/rdb/cdc.yml

## set java path
if [ -z "$JAVA" ] ; then
  JAVA=$(which java)
fi

if [ ! -z "$DEBUG_SUSPEND" ] ; then
    echo ---
    echo "enable debug on :9999!"
    JAVA_DEBUG_OPT="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=9999,server=y,suspend=$DEBUG_SUSPEND"
fi

JAVA_OPTS="-server -Xms2048m -Xmx3072m -Xmn1024m -XX:SurvivorRatio=2 -XX:PermSize=96m -XX:MaxPermSize=256m -Xss256k -XX:-UseAdaptiveSizePolicy -XX:MaxTenuringThreshold=15 -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:+HeapDumpOnOutOfMemoryError"
JAVA_OPTS=" $JAVA_OPTS -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8"
ADAPTER_OPTS="-DappName=canal-adapter"

for i in $BASE/lib/*;
    do CLASSPATH=$i:"$CLASSPATH";
done

CLASSPATH="$BASE/conf:$CLASSPATH";

cd $BASE/bin

# echo CLASSPATH :$CLASSPATH
$JAVA $JAVA_OPTS $JAVA_DEBUG_OPT $ADAPTER_OPTS -classpath .:$CLASSPATH com.alibaba.otter.canal.adapter.launcher.CanalAdapterApplication
