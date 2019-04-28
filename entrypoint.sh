#!/usr/local/bin/dumb-init /bin/sh

/etc/init.d/mysql start
cd /hadoop-3.1.2
/usr/sbin/sshd -p 22
./sbin/start-dfs.sh
sleep 5
./bin/hdfs --daemon start httpfs
cd /apache-hive-3.1.1-bin
./bin/hive --service metastore &
sleep 5
cd /presto-server-0.218
bin/launcher run

