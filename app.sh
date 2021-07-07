#!/bin/bash

export LANG=en_US.UTF-8

if [ -z "$BASE" ] ; then
    BASE=/opt/canal-adapter
fi

cd $BASE

CANAL_DESTINATIONS=$(perl -le 'print $ENV{"canal.destinations"} || "cdc"')
CDC_MYSQL_JDBC_URL=$(perl -le 'print $ENV{"cdc.mysql.jdbc.url"} || ""')
CDC_MYSQL_JDBC_USERNAME=$(perl -le 'print $ENV{"cdc.mysql.jdbc.username"} || ""')
CDC_MYSQL_JDBC_PASSWORD=$(perl -le 'print $ENV{"cdc.mysql.jdbc.password"} || ""')
CDC_MYSQL_JDBC_DATABASE=$(perl -le 'print $ENV{"cdc.mysql.jdbc.database"} || ""')

sed "s/  - instance: .*/  - instance: ${CANAL_DESTINATIONS}/" $BASE/conf/application.yml
cat <<EOF>> $BASE/conf/application.yml
      - name: rdb
        key: mysql
        properties:
          jdbc.driverClassName: com.mysql.jdbc.Driver
          jdbc.url: ${CDC_MYSQL_JDBC_URL}
          jdbc.username: ${CDC_MYSQL_JDBC_USERNAME}
          jdbc.password: ${CDC_MYSQL_JDBC_PASSWORD}
EOF

rm $BASE/conf/rdb/mytest_user.yml
cat <<EOF> $BASE/conf/rdb/cdc.yml
dataSourceKey: defaultDS
destination: ${CANAL_DESTINATIONS}
groupId: g1
outerAdapterKey: mysql
concurrent: true
dbMapping:
  mirrorDb: true
  database: ${CDC_MYSQL_JDBC_DATABASE}
EOF


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

str=`file -L $JAVA | grep 64-bit`
if [ -n "$str" ]; then
	JAVA_OPTS="-server -Xms2048m -Xmx3072m -Xmn1024m -XX:SurvivorRatio=2 -XX:PermSize=96m -XX:MaxPermSize=256m -Xss256k -XX:-UseAdaptiveSizePolicy -XX:MaxTenuringThreshold=15 -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:+HeapDumpOnOutOfMemoryError"
else
	JAVA_OPTS="-server -Xms1024m -Xmx1024m -XX:NewSize=256m -XX:MaxNewSize=256m -XX:MaxPermSize=128m "
fi

JAVA_OPTS=" $JAVA_OPTS -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8"
ADAPTER_OPTS="-DappName=canal-adapter"

for i in $BASE/lib/*;
    do CLASSPATH=$i:"$CLASSPATH";
done

CLASSPATH="$BASE/conf:$CLASSPATH";

# echo CLASSPATH :$CLASSPATH
$JAVA $JAVA_OPTS $JAVA_DEBUG_OPT $ADAPTER_OPTS -classpath .:$CLASSPATH com.alibaba.otter.canal.adapter.launcher.CanalAdapterApplication
