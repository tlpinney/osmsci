#!/usr/local/bin/dumb-init /bin/sh

# format namenode
cd /hadoop-3.1.2
./bin/hdfs namenode -format


# set up hive tables 
cd /hadoop-3.1.2
/usr/sbin/sshd -p 22
./sbin/start-dfs.sh 
./bin/hdfs dfs -mkdir -p /user/root 
./bin/hdfs dfs -mkdir -p /tmp
./bin/hdfs dfs -mkdir -p /user/hive/warehouse
./bin/hdfs dfs -chmod g+w /tmp
./bin/hdfs dfs -chmod g+w /user/hive/warehouse

# remove stale metastore
cd /apache-hive-3.1.1-bin 
rm -rf metastore_db

# setup mysql
mkdir -p /tank/mysql && chown mysql /tank/mysql
mysqld --initialize-insecure --user=root 
/etc/init.d/mysql start 
echo "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root'; " | mysql -u root --skip-password
cd /apache-hive-3.1.1-bin
./bin/schematool -initSchema -dbType mysql

